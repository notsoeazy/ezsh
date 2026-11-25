#!/usr/bin/env python3
"""Wallpaper discovery and thumbnails for WallpaperService.

Usage:
  wallpapers.py scan DIR [EXTRA...]
      Prints JSON {"images": [path...], "sizes": {path: [w, h]}} for every JPG/PNG/WebP under
      DIR (recursive, hidden entries and directory symlinks skipped), sorted by file name.
      Sizes are read from the header only, rotated by EXIF orientation like Qt's autoTransform.
      Each EXTRA that exists (the kept wallpaper) gets a size too, but is not listed in images.
  wallpapers.py thumbs WIDTH HEIGHT PATH...
      Prints one JSON line [path, thumb or null] per PATH, in the order given, as each is ready.
      Thumbnails are WIDTH x HEIGHT center crops in $XDG_CACHE_HOME/ezsh/wallpaper-thumbs, named
      after the source's path, mtime and the size; files no longer used are deleted at the end.
  wallpapers.py fit WIDTH HEIGHT PATH
      Prints JSON "/path/to/copy.png": PATH scaled down to just cover WIDTH x HEIGHT, for images
      too large for Qt to decode (its default limit is 256 MiB decoded). Cached in
      $XDG_CACHE_HOME/ezsh/wallpaper-fit under the same kind of name.
  wallpapers.py keep PATH TARGET
      Hard-links PATH to TARGET (a copy across filesystems), so the wallpaper stays when PATH is
      deleted or moved, and removes older kept copies with another extension. Does nothing when
      TARGET already holds PATH.

Why a separate process: decoding hundreds of multi-megapixel images in the shell would block it
and leave Qt holding the decoded memory. Needs Pillow (python-pillow).
"""

import hashlib
import json
import math
import os
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageOps

EXTENSIONS = (".jpg", ".jpeg", ".png", ".webp")
CACHE_ROOT = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "ezsh"
CACHE = CACHE_ROOT / "wallpaper-thumbs"
FIT_CACHE = CACHE_ROOT / "wallpaper-fit"
ROTATED = (5, 6, 7, 8)  # EXIF orientations that swap width and height


def scan(directory: str, extras: list) -> None:
    images, sizes = [], {}
    for root, dirs, files in os.walk(directory):  # followlinks=False: no symlink loops
        dirs[:] = [d for d in dirs if not d.startswith(".") and not os.path.islink(os.path.join(root, d))]
        for name in files:
            if not name.startswith(".") and os.path.splitext(name)[1].lower() in EXTENSIONS:
                images.append(os.path.join(root, name))
    images.sort(key=lambda path: (os.path.basename(path).casefold(), path))
    for path in images + [e for e in extras if os.path.isfile(e)]:
        try:
            with Image.open(path) as image:  # reads only the header
                width, height = image.size
                # PNG getexif() decodes the whole image to find a trailing eXIf chunk; skip it.
                if image.format != "PNG" and image.getexif().get(0x0112) in ROTATED:
                    width, height = height, width
                sizes[path] = [width, height]
        except Exception as error:  # incl. DecompressionBombError: one bad file must not end the scan
            print(f"wallpapers: {path}: {error}", file=sys.stderr)
    json.dump({"images": images, "sizes": sizes}, sys.stdout)


def cache_name(path: str, width: int, height: int) -> str:
    stat = os.stat(path)
    return hashlib.sha1(f"{path}\0{stat.st_mtime_ns}\0{width}x{height}".encode()).hexdigest()


def thumbnail(path: str, width: int, height: int):
    target = CACHE / f"{cache_name(path, width, height)}.jpg"
    if not target.is_file():
        with Image.open(path) as image:
            image.draft("RGB", (width * 2, height * 2))  # JPEG: decode at a fraction of full size
            image = ImageOps.fit(ImageOps.exif_transpose(image).convert("RGB"), (width, height), Image.LANCZOS)
            CACHE.mkdir(parents=True, exist_ok=True)
            partial = target.with_suffix(".tmp")
            image.save(partial, "JPEG", quality=85)
            partial.replace(target)  # atomic, so the shell never reads half a file
    return target


def thumbs(width: int, height: int, paths: list) -> None:
    used = set()
    for path in paths:
        try:
            target = thumbnail(path, width, height)
            used.add(target.name)
            result = str(target)
        except Exception as error:  # one bad file must not stop the others
            print(f"wallpapers: {path}: {error}", file=sys.stderr)
            result = None
        print(json.dumps([path, result]), flush=True)
    if CACHE.is_dir():
        for stale in CACHE.iterdir():
            if stale.name not in used:
                stale.unlink(missing_ok=True)


def fit(width: int, height: int, path: str) -> None:
    # shortcut: copies are never pruned; they are few (only images over Qt's limit), prune if that changes.
    target = FIT_CACHE / f"{cache_name(path, width, height)}.png"
    if not target.is_file():
        with Image.open(path) as image:
            image = ImageOps.exif_transpose(image)
            # Same size Background asks Qt for: cover the target, never enlarge.
            scale = min(1, max(width / image.width, height / image.height))
            image = image.resize((max(1, math.ceil(image.width * scale)), max(1, math.ceil(image.height * scale))), Image.LANCZOS)
            FIT_CACHE.mkdir(parents=True, exist_ok=True)
            partial = target.with_suffix(".tmp")
            image.save(partial, "PNG", compress_level=1)
            partial.replace(target)
    json.dump(str(target), sys.stdout)


def same_file(a: str, b: Path) -> bool:
    """b is a's hard link, or a copy made by keep (copy2 keeps size and mtime)."""
    if not b.is_file():
        return False
    sa, sb = os.stat(a), b.stat()
    return (sa.st_dev, sa.st_ino) == (sb.st_dev, sb.st_ino) or (sa.st_size, sa.st_mtime_ns) == (sb.st_size, sb.st_mtime_ns)


def keep(path: str, target: str) -> None:
    target = Path(target)
    if not same_file(path, target):
        target.parent.mkdir(parents=True, exist_ok=True)
        partial = target.with_name(f".{target.name}.tmp")
        partial.unlink(missing_ok=True)
        try:
            os.link(path, partial)
        except OSError:  # another filesystem, or one without hard links
            shutil.copy2(path, partial)
        partial.replace(target)  # atomic, so the shell never reads half a file
    for older in target.parent.glob(f"{target.stem}.*"):
        if older != target:
            older.unlink(missing_ok=True)


def main() -> int:
    if len(sys.argv) >= 3 and sys.argv[1] == "scan":
        scan(sys.argv[2], sys.argv[3:])
    elif len(sys.argv) >= 4 and sys.argv[1] == "thumbs":
        thumbs(int(sys.argv[2]), int(sys.argv[3]), sys.argv[4:])
    elif len(sys.argv) == 5 and sys.argv[1] == "fit":
        fit(int(sys.argv[2]), int(sys.argv[3]), sys.argv[4])
    elif len(sys.argv) == 4 and sys.argv[1] == "keep":
        keep(sys.argv[2], sys.argv[3])
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
