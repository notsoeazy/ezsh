#!/usr/bin/env python3
"""Color schemes for ThemeService: predefined palettes, matugen seeds and wallpaper colors.

Usage:
  theme.py list WALLPAPER
      Prints JSON [{"id", "name", "light", "preview": {"dark": {...}, "light": {...}}}] for every
      theme in themes/palettes, in file order (default.json first). A preview holds the card's
      "surface", "onSurface" and five "swatches". WALLPAPER ("" for none) feeds the Dynamic theme.
  theme.py colors THEME MODE WALLPAPER
      Prints JSON {"id", "name", "mode", "colors": {role: "#rrggbb"}} without writing anything.
      MODE is dark or light; a theme without a light palette stays dark (the printed mode says so).
  theme.py apply THEME MODE WALLPAPER OUTDIR COLORS
      Like colors, then renders every file in themes/templates to the same relative path under
      OUTDIR, writes COLORS (the same JSON, read by Theme.qml) last, pushes the terminal colors into
      every open terminal and sets GTK's color-scheme preference.

Palettes come in four kinds: "roles" (every M3 role given), a compact upstream palette (base,
surfaces, text, three accents, error and 16 terminal colors), "seed" (a matugen source color,
optional "type") and "image" (matugen on WALLPAPER). Templates use {{role}} for "rrggbb" (no "#"),
plus {{mode}} and {{name}}. Needs matugen for seed and image palettes.
"""

import colorsys
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

THEMES = Path(__file__).resolve().parent.parent / "themes"
PALETTES = THEMES / "palettes"
TEMPLATES = THEMES / "templates"

ACCENTS = ("primary", "secondary", "tertiary")
# Standard terminal hues (red, green, yellow, blue, magenta, cyan), pulled toward the primary.
TERM_HUES = (5, 130, 48, 215, 295, 180)
HUE_PULL = 0.2


# --- color helpers ---------------------------------------------------------------------------

def rgb(hex_color):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def to_hex(r, g, b):
    return "#" + "".join(f"{round(max(0, min(1, c)) * 255):02x}" for c in (r, g, b))


def mix(a, b, amount):
    """a moved `amount` (0..1) of the way to b."""
    return to_hex(*(x + (y - x) * amount for x, y in zip(rgb(a), rgb(b))))


def luminance(color):
    def channel(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (channel(c) for c in rgb(color))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


# --- palettes ----------------------------------------------------------------------------------

def load():
    """Returns (themes in order, palettes by name)."""
    files = sorted(PALETTES.glob("*.json"), key=lambda p: (p.name != "default.json", p.name))
    themes, palettes = [], {}
    for file in files:
        data = json.loads(file.read_text())
        themes += data["themes"]
        palettes.update(data["palettes"])
    return themes, palettes


def from_palette(p):
    """M3 roles from a compact upstream palette; missing surfaces are mixed from base and text."""
    base, text = p["base"], p["text"]
    dark = luminance(base) < luminance(text)
    shade = "#000000" if dark else text
    mantle = p.get("mantle") or mix(base, shade, 0.15 if dark else 0.05)
    crust = p.get("crust") or mix(base, shade, 0.3 if dark else 0.1)
    s0 = p.get("surface0") or mix(base, text, 0.08)
    s1 = p.get("surface1") or mix(base, text, 0.15)
    s2 = p.get("surface2") or mix(base, text, 0.24)
    # Text on an accent: whichever of the scheme's own neutrals reads best on it.
    neutrals = (crust, base, text, mix(text, "#000000", 0.5))
    roles = {
        "background": base, "onBackground": text,
        "surface": base, "onSurface": text,
        "surfaceDim": mantle, "surfaceBright": s2,
        "surfaceContainerLowest": crust, "surfaceContainerLow": mantle, "surfaceContainer": s0,
        "surfaceContainerHigh": s1, "surfaceContainerHighest": s2,
        "surfaceVariant": s1, "onSurfaceVariant": p["subtext"],
        "outline": p["overlay"], "outlineVariant": s2,
        "inverseSurface": text, "inverseOnSurface": base,
        "inversePrimary": mix(p["primary"], "#000000" if dark else "#ffffff", 0.4),
        "surfaceTint": p["primary"],
        "shadow": "#000000", "scrim": "#000000",
    }
    for name in ACCENTS + ("error",):
        color = p[name]
        cap = name[0].upper() + name[1:]
        on_accent = max(neutrals, key=lambda n: contrast(n, color))
        roles[name] = color
        roles[f"on{cap}"] = on_accent
        roles[f"{name}Container"] = mix(base, color, 0.3 if dark else 0.25)
        roles[f"on{cap}Container"] = mix(color, text, 0.45)
        if name != "error":
            roles[f"{name}Fixed"] = color
            roles[f"{name}FixedDim"] = mix(color, "#000000", 0.15)
            roles[f"on{cap}Fixed"] = on_accent
            roles[f"on{cap}FixedVariant"] = mix(on_accent, color, 0.3)
    roles.update({f"term{i}": c for i, c in enumerate(p["term"])})
    return roles


def from_matugen(args, mode):
    out = subprocess.run(["matugen", *args, "--dry-run", "-j", "hex", "-m", mode, "-q"],
                         capture_output=True, text=True, check=True).stdout
    colors = json.loads(out)["colors"]
    return {re.sub(r"_(\w)", lambda m: m.group(1).upper(), key): value[mode]["color"]
            for key, value in colors.items() if key != "source_color"}


def terminal_colors(roles, dark):
    """16 ANSI colors for a generated scheme: standard hues nudged toward the primary."""
    hue, _, saturation = colorsys.rgb_to_hls(*rgb(roles["primary"]))
    tint = 1 if saturation > 0.08 else 0.25  # a gray scheme gets muted colors
    colors = {}
    for i, base_hue in enumerate(TERM_HUES, start=1):
        diff = ((hue * 360 - base_hue + 180) % 360) - 180
        h = ((base_hue + diff * HUE_PULL) % 360) / 360
        for slot, (light, sat) in ((i, (0.68, 0.55) if dark else (0.4, 0.65)),
                                   (i + 8, (0.78, 0.65) if dark else (0.32, 0.7))):
            colors[f"term{slot}"] = to_hex(*colorsys.hls_to_rgb(h, light, sat * tint))
    if dark:
        ends = ("surfaceContainerHighest", "onSurfaceVariant", "outline", "onSurface")
    else:
        ends = ("onSurfaceVariant", "surfaceContainerHighest", "outline", "surfaceContainerLow")
    for slot, role in zip((0, 7, 8, 15), ends):
        colors[f"term{slot}"] = roles[role]
    return colors


def scheme(theme, mode, palettes, wallpaper):
    """(effective mode, roles) for a theme entry."""
    if mode == "light" and not theme.get("light"):
        mode = "dark"
    p = palettes[theme[mode]]
    if "roles" in p:
        roles = dict(p["roles"])
    elif "seed" in p:
        roles = from_matugen(["color", "hex", p["seed"], "-t", p.get("type", "scheme-tonal-spot")], mode)
    elif "image" in p:
        if not wallpaper:
            raise ValueError("the dynamic theme needs a wallpaper")
        roles = from_matugen(["image", wallpaper, "--source-color-index", "0"], mode)
    else:
        roles = from_palette(p)
    if "term0" not in roles:
        roles.update(terminal_colors(roles, mode == "dark"))
    return mode, roles


def find(theme_id):
    themes, palettes = load()
    theme = next((t for t in themes if t["id"] == theme_id), None)
    if not theme:
        raise ValueError(f"unknown theme {theme_id}")
    return theme, palettes


# --- commands -----------------------------------------------------------------------------------

def preview(roles):
    return {
        "surface": roles["surfaceContainer"],
        "onSurface": roles["onSurface"],
        "swatches": [roles[k] for k in ("primary", "secondary", "tertiary", "outline", "onSurface")],
    }


def list_themes(wallpaper):
    themes, palettes = load()

    def entry(theme):
        try:
            modes = {}
            for mode in ("dark", "light") if theme.get("light") else ("dark",):
                modes[mode] = preview(scheme(theme, mode, palettes, wallpaper)[1])
            return {"id": theme["id"], "name": theme["name"], "light": "light" in modes, "preview": modes}
        except (ValueError, KeyError, json.JSONDecodeError, OSError, subprocess.CalledProcessError) as error:
            print(f"theme.py: skipping {theme['id']}: {error}", file=sys.stderr)
            return None

    with ThreadPoolExecutor() as pool:
        print(json.dumps([e for e in pool.map(entry, themes) if e]))


def resolve(theme_id, mode, wallpaper):
    theme, palettes = find(theme_id)
    mode, roles = scheme(theme, mode, palettes, wallpaper)
    return {"id": theme["id"], "name": theme["name"], "mode": mode, "colors": roles}


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp")
    tmp.write_text(text)
    tmp.replace(path)


def render(template, result):
    values = {k: v.lstrip("#") for k, v in result["colors"].items()}
    values.update(mode=result["mode"], name=result["name"])
    return re.sub(r"\{\{\s*(\w+)\s*\}\}", lambda m: values[m.group(1)], template)


def sequences(colors):
    """OSC sequences that recolor a running terminal: 4 palette, 10 fg, 11 bg, 12 cursor, 17 selection."""
    def osc(color, *codes):
        h = color.lstrip("#")
        return f"\x1b]{';'.join(map(str, codes))};rgb:{h[0:2]}/{h[2:4]}/{h[4:6]}\x1b\\"
    out = osc(colors["onSurface"], 10) + osc(colors["surface"], 11) + osc(colors["primary"], 12)
    out += osc(colors["surfaceContainerHighest"], 17)
    return out + "".join(osc(colors[f"term{i}"], 4, i) for i in range(16))


def push_to_terminals(colors):
    data = sequences(colors).encode()
    uid = os.getuid()
    for pt in Path("/dev/pts").iterdir():
        if not pt.name.isdigit():
            continue
        try:
            if pt.stat().st_uid != uid:
                continue
            fd = os.open(pt, os.O_WRONLY | os.O_NONBLOCK | os.O_NOCTTY)
            try:
                os.write(fd, data)
            finally:
                os.close(fd)
        except OSError:
            pass  # closed or busy terminals are skipped


def apply(theme_id, mode, wallpaper, outdir, colors_file):
    result = resolve(theme_id, mode, wallpaper)
    # Rendered before anything is written, so a bad template leaves every file as it was.
    rendered = [(Path(outdir) / t.relative_to(TEMPLATES), render(t.read_text(), result))
                for t in sorted(p for p in TEMPLATES.rglob("*") if p.is_file())]
    for path, text in rendered:
        write(path, text)
    # Last, so a failed apply leaves the shell on its old colors like everything else.
    write(Path(colors_file), json.dumps(result, indent=2) + "\n")
    push_to_terminals(result["colors"])
    try:
        subprocess.run(["dconf", "write", "/org/gnome/desktop/interface/color-scheme",
                        f"'prefer-{result['mode']}'"], check=False)
    except OSError:
        pass  # no dconf: GTK keeps its preference
    return result


def main():
    args = sys.argv[1:]
    try:
        if args[:1] == ["list"] and len(args) == 2:
            list_themes(args[1])
        elif args[:1] == ["colors"] and len(args) == 4:
            print(json.dumps(resolve(*args[1:])))
        elif args[:1] == ["apply"] and len(args) == 6:
            print(json.dumps(apply(*args[1:])))
        else:
            sys.exit(__doc__)
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(f"theme.py: {error}")


if __name__ == "__main__":
    main()
