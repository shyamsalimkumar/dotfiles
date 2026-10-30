#!/usr/bin/env python3
"""Offline pixel-art tool: draw sprites as text grids, render them to sprite
sheets, and lint them against the pixel-art rules in ../SKILL.md.

.pix format (one file per sprite or tile set):

    palette: sweetie-16          # bundled name, or a path to a .hex file
    size: 16x16                  # frame width x height
    outline: 0                   # optional: palette index used for outlines
    fps: 8                       # optional default animation speed
    === idle_0                   # one block per frame: <animation>_<n>
    ......0000......
    ...                          # '.' = transparent, 0-9 a-z A-Z = palette index

Frames named <anim>_<n> become one sheet row per animation, in file order.
"""
import argparse
import json
import re
import sys
from pathlib import Path

from PIL import Image

DIGITS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
BUNDLED = Path(__file__).resolve().parents[2] / "game-art-brief" / "palettes"


def load_palette(ref, base=Path(".")):
    path = Path(ref)
    if not path.suffix:
        path = BUNDLED / f"{ref}.hex"
    elif not path.is_absolute():
        path = base / path
    if not path.exists():
        names = ", ".join(p.stem for p in sorted(BUNDLED.glob("*.hex")))
        sys.exit(f"palette '{ref}' not found; bundled: {names}")
    colors = [line.strip().lstrip("#") for line in path.read_text().splitlines() if line.strip()]
    return [tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) for c in colors]


def parse(path):
    meta, frames, current = {}, {}, None
    for n, raw in enumerate(Path(path).read_text().splitlines(), 1):
        line = raw.split("#", 1)[0].rstrip() if not raw.startswith("===") else raw.strip()
        if not line:
            continue
        if line.startswith("==="):
            current = line[3:].strip()
            if not re.fullmatch(r".+_\d+", current):
                sys.exit(f"{path}:{n}: frame name '{current}' must be <animation>_<number>")
            frames[current] = []
        elif current is None:
            key, _, value = line.partition(":")
            meta[key.strip()] = value.strip()
        else:
            frames[current].append(line.strip())
    if "size" not in meta or "palette" not in meta:
        sys.exit(f"{path}: needs 'palette:' and 'size:' header lines")
    meta["w"], meta["h"] = map(int, meta["size"].lower().split("x"))
    return meta, frames


def grid_errors(meta, name, rows, palette_len):
    errors = []
    if len(rows) != meta["h"]:
        errors.append(f"{name}: {len(rows)} rows, expected {meta['h']}")
    for y, row in enumerate(rows):
        if len(row) != meta["w"]:
            errors.append(f"{name} row {y}: {len(row)} columns, expected {meta['w']}")
        for x, ch in enumerate(row):
            if ch != "." and (ch not in DIGITS or DIGITS.index(ch) >= palette_len):
                errors.append(f"{name} ({x},{y}): '{ch}' is not a palette index")
    return errors


def animations(frames):
    anims = {}
    for name in frames:
        anim = name.rsplit("_", 1)[0]
        anims.setdefault(anim, []).append(name)
    return anims


def render(args):
    meta, frames = parse(args.file)
    palette = load_palette(meta["palette"], Path(args.file).parent)
    errors = [e for name, rows in frames.items() for e in grid_errors(meta, name, rows, len(palette))]
    if errors:
        sys.exit("\n".join(errors))
    anims = animations(frames)
    w, h = meta["w"], meta["h"]
    cols = max(len(v) for v in anims.values())
    sheet = Image.new("RGBA", (cols * w, len(anims) * h), (0, 0, 0, 0))
    info = {"frame": [w, h], "animations": {}}
    for row, (anim, names) in enumerate(anims.items()):
        for col, name in enumerate(names):
            for y, line in enumerate(frames[name]):
                for x, ch in enumerate(line):
                    if ch != ".":
                        sheet.putpixel((col * w + x, row * h + y), palette[DIGITS.index(ch)] + (255,))
        info["animations"][anim] = {"row": row, "cols": list(range(len(names))),
                                    "fps": int(meta.get("fps", 8)), "loop": True}
    out = Path(args.out or Path(args.file).with_suffix(".png"))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    info["image"] = out.name
    out.with_suffix(".json").write_text(json.dumps(info, indent=2) + "\n")
    print(f"wrote {out} ({sheet.width}x{sheet.height}, {len(anims)} animations) and {out.with_suffix('.json').name}")


def doubles(rows, color):
    """L-shaped corner pixels on a 1px line: removing one keeps the line joined
    diagonally. A box corner (both arms run on straight) is not a double.
    Found pixels are dropped as we go, so each staircase step is reported once."""
    filled = {(x, y) for y, r in enumerate(rows) for x, c in enumerate(r) if c == color}
    found = []
    for x, y in sorted(filled, key=lambda p: (p[1], p[0])):
        n4 = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (x + dx, y + dy) in filled]
        if len(n4) != 2 or n4[0][0] == n4[1][0] or n4[0][1] == n4[1][1]:
            continue
        runs_on = [(2 * nx - x, 2 * ny - y) in filled for nx, ny in n4]
        opposite = (n4[0][0] + n4[1][0] - x, n4[0][1] + n4[1][1] - y)
        if not any(runs_on) and opposite not in filled:
            found.append((x, y))
            filled.discard((x, y))
    return found


def has_outline(rows):
    """True when the shape's edge is mostly one color that the inside doesn't use."""
    h, w = len(rows), len(rows[0])
    opaque = lambda x, y: 0 <= x < w and 0 <= y < h and rows[y][x] != "."
    edge, inside = [], []
    for y in range(h):
        for x in range(w):
            if opaque(x, y):
                on_edge = not all(opaque(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                (edge if on_edge else inside).append(rows[y][x])
    if not edge:
        return None
    top = max(set(edge), key=edge.count)
    return edge.count(top) / len(edge) >= 0.7 and (not inside or top != max(set(inside), key=inside.count))


def check(args):
    problems, outlined = [], {}
    for file in args.files:
        meta, frames = parse(file)
        palette = load_palette(meta["palette"], Path(file).parent)
        used = set()
        for name, rows in frames.items():
            errors = grid_errors(meta, name, rows, len(palette))
            problems += [f"{file}: {e}" for e in errors]
            if errors:
                continue
            used |= {c for r in rows for c in r if c != "."}
            if "outline" in meta:
                for x, y in doubles(rows, meta["outline"]):
                    problems.append(f"{file}: {name} ({x},{y}): double on the outline, remove it")
            framed = has_outline(rows)
            if framed is not None:
                outlined.setdefault(file, []).append(framed)
        if args.max_colors and len(used) > args.max_colors:
            problems.append(f"{file}: uses {len(used)} colors, brief allows {args.max_colors}")
        print(f"{file}: {len(frames)} frames, {len(used)} colors, "
              f"outlined: {'yes' if all(outlined.get(file, [False])) else 'no'}")
    kinds = {all(v) for v in outlined.values()}
    if len(kinds) > 1:
        problems.append("outlines are mixed: some sprites have one, some don't; pick one rule for the whole game")
    print("\n".join(problems) if problems else "ok: no problems found")
    sys.exit(1 if problems else 0)


def palette_cmd(args):
    if args.name is None:
        for p in sorted(BUNDLED.glob("*.hex")):
            print(f"{p.stem}: {len(load_palette(p.stem))} colors")
        return
    for i, rgb in enumerate(load_palette(args.name)):
        print(f"{DIGITS[i]} #{''.join(f'{c:02x}' for c in rgb)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("render", help="render a .pix file to a sprite sheet PNG + JSON")
    p.add_argument("file")
    p.add_argument("-o", "--out", help="output PNG path (default: next to the .pix)")
    p.set_defaults(func=render)
    p = sub.add_parser("check", help="lint .pix files: grid, palette, doubles, outline consistency")
    p.add_argument("files", nargs="+")
    p.add_argument("--max-colors", type=int)
    p.set_defaults(func=check)
    p = sub.add_parser("palette", help="list bundled palettes, or print one with its index characters")
    p.add_argument("name", nargs="?")
    p.set_defaults(func=palette_cmd)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
