#!/usr/bin/env python3
"""Small thumbnails for app icons that only exist as large rasters.

Usage: icon-thumbs.py SIZE NAME...   (NAME: an icon name or an absolute path)
Prints JSON {"theme": ..., "icons": {NAME: "/path/to/thumb.png" or null}} on stdout.

Why: Qt keeps ~20-40 MiB per process after decoding one 512/1024 px PNG, even to draw it
at 32 px (measured; see 01-references/rules.md "Loading and memory"). Decoding here, in a
short-lived process, and handing the shell a SIZE px copy avoids that.

Each NAME is resolved the way Qt's icon loader does (freedesktop icon theme spec): the
icon theme and its Inherits chain, then hicolor, then /usr/share/pixmaps. null means the
theme's own icon is already cheap (an SVG or a raster no larger than SIZE) or there is
none, so the shell should load it normally.

Thumbnails go to $XDG_CACHE_HOME/ezsh/icon-thumbs, named after the source's path, mtime
and SIZE, so an updated icon gets a new thumbnail. Files no longer used are deleted.
Needs Pillow (python-pillow).
"""

import configparser
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

from PIL import Image

ICON_DIRS = [Path.home() / ".local/share/icons", Path.home() / ".icons"] + [
    Path(d) / "icons" for d in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
]
PIXMAPS = Path("/usr/share/pixmaps")
EXTENSIONS = (".png", ".svg", ".xpm")
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "ezsh" / "icon-thumbs"


def icon_theme() -> str:
    """The icon theme Qt uses: qtengine, then qt6ct, then GNOME's setting, then hicolor."""
    try:
        config = json.loads((Path.home() / ".config/qtengine/config.json").read_text())
        if config.get("theme", {}).get("iconTheme"):
            return config["theme"]["iconTheme"]
    except (OSError, ValueError):
        pass
    try:
        parser = configparser.ConfigParser(interpolation=None)
        parser.read(Path.home() / ".config/qt6ct/qt6ct.conf")
        if parser.get("Appearance", "icon_theme", fallback=""):
            return parser.get("Appearance", "icon_theme")
    except configparser.Error:
        pass
    try:
        out = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"],
                             capture_output=True, text=True, timeout=2).stdout.strip().strip("'")
        if out:
            return out
    except (OSError, subprocess.SubprocessError):
        pass
    return "hicolor"


LISTINGS = {}


def listing(directory: Path) -> set:
    """File names in `directory`, read once: probing ~1000 theme dirs per icon is the slow part."""
    if directory not in LISTINGS:
        try:
            LISTINGS[directory] = set(os.listdir(directory))
        except OSError:
            LISTINGS[directory] = set()
    return LISTINGS[directory]


class Theme:
    def __init__(self, name: str):
        self.roots = [d / name for d in ICON_DIRS if (d / name / "index.theme").is_file()]
        self.dirs = []  # (path, type, size, min, max, threshold, scale)
        self.inherits = []
        if not self.roots:
            return
        index = configparser.ConfigParser(interpolation=None, strict=False)
        index.read(self.roots[0] / "index.theme")
        self.inherits = [t for t in index.get("Icon Theme", "Inherits", fallback="").split(",") if t]
        for sub in index.get("Icon Theme", "Directories", fallback="").split(","):
            if not sub or not index.has_section(sub):
                continue
            size = index.getint(sub, "Size", fallback=0)
            self.dirs.append((sub, index.get(sub, "Type", fallback="Threshold"), size,
                              index.getint(sub, "MinSize", fallback=size), index.getint(sub, "MaxSize", fallback=size),
                              index.getint(sub, "Threshold", fallback=2), index.getint(sub, "Scale", fallback=1)))

    def lookup(self, name: str, want: int):
        """The file the spec's LookupIcon picks for `name` at `want` px, or None."""
        best, best_distance = None, None
        for sub, kind, size, lo, hi, threshold, scale in self.dirs:
            for root in self.roots:
                files = listing(root / sub)
                for ext in EXTENSIONS:
                    if name + ext not in files:
                        continue
                    path = root / sub / (name + ext)
                    if kind == "Fixed":
                        distance = abs(size * scale - want)
                    elif kind == "Scalable":
                        distance = 0 if lo * scale <= want <= hi * scale else min(abs(lo * scale - want), abs(hi * scale - want))
                    else:
                        distance = 0 if (size - threshold) * scale <= want <= (size + threshold) * scale else min(
                            abs((size - threshold) * scale - want), abs((size + threshold) * scale - want))
                    if best_distance is None or distance < best_distance:
                        best, best_distance = path, distance
        return best


THEMES = {}


def load_theme(name: str) -> Theme:
    if name not in THEMES:
        THEMES[name] = Theme(name)
    return THEMES[name]


def resolve(name: str, theme: str, want: int):
    if os.path.isabs(name):
        return Path(name) if Path(name).is_file() else None
    seen, queue = set(), [theme]
    while queue:  # the theme, then its Inherits chain breadth-first, hicolor last
        current = queue.pop(0)
        if current in seen:
            continue
        seen.add(current)
        found = load_theme(current).lookup(name, want)
        if found:
            return found
        queue += [t for t in load_theme(current).inherits if t not in seen]
        if not queue and "hicolor" not in seen:
            queue.append("hicolor")
    for ext in EXTENSIONS:
        if (PIXMAPS / (name + ext)).is_file():
            return PIXMAPS / (name + ext)
    return None


def thumbnail(source: Path, size: int):
    """A SIZE px copy of `source` if it is a raster larger than that, else None."""
    if source.suffix == ".svg":
        return None
    try:
        with Image.open(source) as image:  # opening reads only the header
            if max(image.size) <= size:
                return None
            stat = source.stat()
            key = hashlib.sha1(f"{source}\0{stat.st_mtime_ns}\0{size}".encode()).hexdigest()
            target = CACHE / f"{key}.png"
            if not target.is_file():
                image.thumbnail((size, size), Image.LANCZOS)
                CACHE.mkdir(parents=True, exist_ok=True)
                partial = target.with_suffix(".tmp")
                image.convert("RGBA").save(partial, "PNG")
                partial.replace(target)  # atomic, so the shell never reads half a file
            return target
    except OSError as error:
        print(f"icon-thumbs: {source}: {error}", file=sys.stderr)
        return None


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    size = int(sys.argv[1])
    theme = icon_theme()
    icons = {}
    for name in dict.fromkeys(sys.argv[2:]):
        source = resolve(name, theme, size)
        target = thumbnail(source, size) if source else None
        icons[name] = str(target) if target else None

    used = {Path(p).name for p in icons.values() if p}
    if CACHE.is_dir():
        for stale in CACHE.iterdir():
            if stale.name not in used:
                stale.unlink(missing_ok=True)

    json.dump({"theme": theme, "icons": icons}, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
