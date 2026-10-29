#!/usr/bin/env python3
"""Offline Universal LPC character builder. Reads the generator's own data
(sheet_definitions, palette_definitions, spritesheets) from $LPC_HOME
(default ~/.cache/lpc-generator, made by setup.sh) and stacks the layers the
way the web generator does: by zPos, per body type, with palette recolors.

    lpc.py find orc head            # search parts: id, type, colors, licenses
    lpc.py show heads_orc_male      # one part in full
    lpc.py colors cloth             # color names for a material
    lpc.py build -b male body:olive heads_orc_male torso_armour_plate:steel -o orc.png

`build` writes orc.png (standard 832px-wide universal sheet), orc.json (frame
size + animations, the format sprites.py reads) and orc_CREDITS.csv.
"""
import argparse
import csv
import json
import os
import sys
from pathlib import Path

from PIL import Image

LPC = Path(os.environ.get("LPC_HOME", Path.home() / ".cache" / "lpc-generator"))
FRAME, COLS = 64, 13
DIRECTIONS = ["up", "left", "down", "right"]
# From the generator's sources/state/constants.ts: sheet row, rows (4 = one per
# direction), file name, frame cycle.
ANIMS = {
    "spellcast": (0, 4, "spellcast", [0, 1, 2, 3, 4, 5, 6]),
    "thrust": (4, 4, "thrust", [0, 1, 2, 3, 4, 5, 6, 7]),
    "walk": (8, 4, "walk", [1, 2, 3, 4, 5, 6, 7, 8]),
    "slash": (12, 4, "slash", [0, 1, 2, 3, 4, 5]),
    "shoot": (16, 4, "shoot", list(range(13))),
    "hurt": (20, 1, "hurt", [0, 1, 2, 3, 4, 5]),
    "climb": (21, 1, "climb", [0, 1, 2, 3, 4, 5]),
    "idle": (22, 4, "idle", [0, 0, 1]),
    "jump": (26, 4, "jump", [0, 1, 2, 3, 4, 1]),
    "sit": (30, 4, "sit", [0] * 5 + [1] * 5 + [2] * 5),
    "emote": (34, 4, "emote", [0] * 5 + [1] * 5 + [2] * 5),
    "run": (38, 4, "run", [0, 1, 2, 3, 4, 5, 6, 7]),
    "combat": (42, 4, "combat_idle", [0, 0, 1]),
    "1h_backslash": (46, 4, "backslash", [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12]),
    "1h_halfslash": (50, 4, "halfslash", [0, 1, 2, 3, 4, 5]),
}
# Parts with no "animations" list cover only these.
DEFAULT_ANIMS = ["spellcast", "thrust", "walk", "slash", "shoot", "hurt"]
BODY_TYPES = ["male", "female", "teen", "child", "muscular", "pregnant"]


def catalog():
    if not (LPC / "sheet_definitions").is_dir():
        sys.exit(f"LPC data not found at {LPC}: run setup.sh once (needs internet)")
    items = {}
    for f in sorted((LPC / "sheet_definitions").rglob("*.json")):
        d = json.loads(f.read_text())
        if "name" in d and "type_name" in d:
            d["id"], d["file"] = f.stem, f
            items[f.stem] = d
    return items


def layers(d):
    return [d[k] for k in sorted(k for k in d if k.startswith("layer_")) if d[k]]


def recolor_slots(d):
    r = d.get("recolors")
    if not r:
        return []
    return [r] if "material" in r else [r[k] for k in sorted(r)]


def material_meta(material):
    return json.loads((LPC / "palette_definitions" / material / f"meta_{material}.json").read_text())


def palette_file(material, version):
    path = LPC / "palette_definitions" / material / f"{material}_{version}.json"
    return json.loads(path.read_text()) if path.exists() else {}


def palette_sources(slot):
    """(material, version) pairs a slot may pick target colors from."""
    for p in slot["palettes"]:
        yield tuple(p.split(".", 1)) if "." in p else (slot["material"], p)


def source_colors(slot):
    meta = material_meta(slot["material"])
    base = slot.get("base") or meta["base"]
    version, color = base.split(".", 1) if "." in base else (meta["default"], base)
    return palette_file(slot["material"], version)[color]


def target_colors(slot, wanted):
    *prefix, color = wanted.split(".")
    for material, version in palette_sources(slot):
        if prefix and prefix[-1] != version or len(prefix) > 1 and prefix[0] != material:
            continue
        colors = palette_file(material, version).get(color)
        if colors:
            return colors
    return None


def color_names(d):
    if d.get("variants"):
        return "variants: " + " ".join(dict.fromkeys(d["variants"]))
    slots = recolor_slots(d)
    return " | ".join(f"color_{i + 1}: {s['material']} ({', '.join(s['palettes'])})"
                      for i, s in enumerate(slots)) or "no colors"


def licenses(d, body=None):
    return sorted({lic for c in credits_for(d, body) for lic in c.get("licenses", [])})


def credits_for(d, body=None):
    """Credits for the files a body type actually uses (all of them when unsure)."""
    credits = d.get("credits", [])
    if not body:
        return credits
    paths = [layer[body] for layer in layers(d) if body in layer]
    used = [c for c in credits if any(path.startswith(c["file"].rstrip("/") + "/") for path in paths)]
    return used or credits


def drm_safe(d, body=None):
    """Every credited file offers CC0 or OGA-BY, the licenses LPC's README calls
    safe for DRM stores (Steam, App Store)."""
    return all(any(lic.startswith(("CC0", "OGA-BY")) for lic in c.get("licenses", []))
               for c in credits_for(d, body))


def types(_):
    counts = {}
    for d in catalog().values():
        counts[d["type_name"]] = counts.get(d["type_name"], 0) + 1
    print(" ".join(f"{t}({n})" for t, n in sorted(counts.items())))


def find(args):
    words = [w.lower() for w in args.words]
    hits = []
    for d in catalog().values():
        hay = " ".join([d["id"], d["name"], d["type_name"], *d.get("tags", []), str(d["file"].parent)]).lower()
        if all(w in hay for w in words) and (not args.type or d["type_name"] == args.type):
            if args.body and not all(args.body in layer for layer in layers(d)):
                continue
            if args.drm_safe and not drm_safe(d, args.body):
                continue
            hits.append(d)
    for d in hits[: args.limit]:
        print(f"{d['id']} | {d['type_name']} | {d['name']} | {color_names(d)} | {','.join(licenses(d))}")
    if len(hits) > args.limit:
        print(f"... {len(hits) - args.limit} more; add words or --type to narrow")
    if not hits:
        print("no match; try fewer or shorter words")


def show(args):
    d = catalog().get(args.id) or sys.exit(f"unknown id {args.id}")
    print(f"{d['id']}: {d['name']} (type {d['type_name']})")
    print(f"body types: {', '.join(b for b in BODY_TYPES if all(b in layer for layer in layers(d)))}")
    print(f"animations: {', '.join(d.get('animations', DEFAULT_ANIMS))}")
    print(color_names(d))
    if d.get("match_body_color"):
        print("matches body color when no color is given")
    for c in d.get("credits", []):
        print(f"credit: {', '.join(c['authors'])} [{', '.join(c['licenses'])}]")


def colors(args):
    meta = material_meta(args.material)
    version = args.version or meta["default"]
    names = list(palette_file(args.material, version))
    print(f"{args.material} {version} (default base {meta['base']}): {' '.join(names)}")


def pixels(img):
    return img.get_flattened_data() if hasattr(img, "get_flattened_data") else img.getdata()


def recolor(img, mapping):
    """Swap colors within +/-1 per channel, like the generator's shader."""
    lookup = {}
    for src, dst in mapping.items():
        for dr in (-1, 0, 1):
            for dg in (-1, 0, 1):
                for db in (-1, 0, 1):
                    lookup[(src[0] + dr, src[1] + dg, src[2] + db)] = dst
    img.putdata([lookup.get(p[:3], p[:3]) + (p[3],) if p[3] else p for p in pixels(img)])
    return img


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def build(args):
    items = catalog()
    picks, warnings = [], []
    for spec in args.parts:
        pid, _, color = spec.partition(":")
        d = items.get(pid) or sys.exit(f"unknown id '{pid}': use `lpc.py find`")
        picks.append((d, color))
    body_color = next((c for d, c in picks if d.get("match_body_color") and c), None)
    anims = args.anims.split(",") if args.anims else list(ANIMS)
    for a in anims:
        if a not in ANIMS:
            sys.exit(f"unknown animation '{a}'; choose from {', '.join(ANIMS)}")
    head = next((d for d, _ in picks if d["type_name"] == "head"), None)

    draws = []  # (zPos, order, path_or_None, item, mapping, variant)
    for order, (d, color) in enumerate(picks):
        mapping, variant = {}, None
        if d.get("variants"):
            variant = color or d["variants"][0]
            if variant not in d["variants"]:
                sys.exit(f"{d['id']}: no variant '{variant}'; {color_names(d)}")
        else:
            wanted = color.split(",") if color else []
            if not wanted and d.get("match_body_color") and body_color:
                wanted = [body_color]
            for slot, want in zip(recolor_slots(d), wanted):
                target = target_colors(slot, want)
                if not target:
                    sys.exit(f"{d['id']}: no color '{want}'; see `lpc.py colors {slot['material']}`")
                src = source_colors(slot)
                if len(src) != len(target):
                    warnings.append(f"{d['id']}: palette sizes differ ({len(src)} vs {len(target)}), shading may be off")
                mapping.update({hex_rgb(s): hex_rgb(t) for s, t in zip(src, target)})
        for layer in layers(d):
            if "custom_animation" in layer:
                warnings.append(f"{d['id']}: oversize weapon layer skipped (not on the standard sheet)")
                continue
            path = layer.get(args.body)
            if not path:
                warnings.append(f"{d['id']}: has no art for body type '{args.body}'")
                continue
            if "${head}" in path:
                table = d.get("replace_in_path", {}).get("head", {})
                key = head and next((v for k, v in table.items() if k.lower() == head["name"].replace(" ", "_").lower()), None)
                if not key:
                    warnings.append(f"{d['id']}: no art for head '{head and head['name']}', layer skipped")
                    continue
                path = path.replace("${head}", key)
            draws.append((layer.get("zPos", 0), order, path, d, mapping, variant))
    draws.sort(key=lambda t: (t[0], t[1]))

    rows = max(ANIMS[a][0] + ANIMS[a][1] for a in anims)
    sheet = Image.new("RGBA", (FRAME * COLS, FRAME * rows), (0, 0, 0, 0))
    missing = {}
    for anim in anims:
        row, _, fname, _ = ANIMS[anim]
        for _, _, path, d, mapping, variant in draws:
            if anim not in d.get("animations", DEFAULT_ANIMS):
                missing.setdefault(anim, []).append(d["id"])
                continue
            f = LPC / "spritesheets" / (f"{path}{fname}/{variant.replace(' ', '_')}.png" if variant else f"{path}{fname}.png")
            if not f.exists():
                missing.setdefault(anim, []).append(d["id"])
                continue
            img = Image.open(f).convert("RGBA")
            sheet.alpha_composite(recolor(img, mapping) if mapping else img, (0, row * FRAME))
    for anim, ids in missing.items():
        warnings.append(f"{anim}: no art for {', '.join(dict.fromkeys(ids))} (left blank)")

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    meta = {"image": out.name, "frame": [FRAME, FRAME], "animations": {},
            "lpc": {"body": args.body, "parts": args.parts}}
    for anim in anims:
        row, n, _, cycle = ANIMS[anim]
        for i in range(n):
            name = anim if n == 1 else f"{anim}_{DIRECTIONS[i]}"
            meta["animations"][name] = {"row": row + i, "cols": cycle, "fps": 8 if anim != "idle" else 3,
                                        "loop": anim not in ("hurt", "slash", "thrust", "spellcast", "shoot")}
    out.with_suffix(".json").write_text(json.dumps(meta, indent=2) + "\n")
    credits_path = out.with_name(out.stem + "_CREDITS.csv")
    with credits_path.open("w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["part", "authors", "licenses", "urls", "notes"])
        for d, _ in picks:
            for c in credits_for(d, args.body):
                w.writerow([d["id"], ", ".join(c["authors"]), ", ".join(c["licenses"]),
                            " ".join(c.get("urls", [])), c.get("notes", "")])
    lics = sorted({lic for d, _ in picks for lic in licenses(d, args.body)})
    print(f"wrote {out} ({sheet.width}x{sheet.height}), {out.with_suffix('.json').name}, {credits_path.name}")
    print(f"licenses: {', '.join(lics)}")
    if args.drm_safe:
        warnings += [f"{d['id']}: not DRM-safe (needs CC0 or OGA-BY), swap it" for d, _ in picks if not drm_safe(d, args.body)]
    for w_ in warnings:
        print(f"warning: {w_}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("find", help="search parts")
    p.add_argument("words", nargs="*")
    p.add_argument("--type", help="exact type_name, e.g. head, hair, torso")
    p.add_argument("--body", choices=BODY_TYPES, help="only parts with art for this body type")
    p.add_argument("--drm-safe", action="store_true", help="only CC0 / OGA-BY parts")
    p.add_argument("--limit", type=int, default=25)
    p.set_defaults(func=find)
    sub.add_parser("types", help="list part types with counts").set_defaults(func=types)
    p = sub.add_parser("show", help="one part in full")
    p.add_argument("id")
    p.set_defaults(func=show)
    p = sub.add_parser("colors", help="color names for a material (body, cloth, hair, metal, wood, eye, all)")
    p.add_argument("material")
    p.add_argument("version", nargs="?", help="ulpc or lpcr (default: the material's default)")
    p.set_defaults(func=colors)
    p = sub.add_parser("build", help="stack parts into a sprite sheet")
    p.add_argument("parts", nargs="+", help="id or id:color (id:c1,c2 for two-color parts)")
    p.add_argument("-b", "--body", choices=BODY_TYPES, default="male")
    p.add_argument("--anims", help="comma list (default: all), e.g. walk,idle,hurt")
    p.add_argument("--drm-safe", action="store_true", help="warn on parts that aren't CC0 / OGA-BY")
    p.add_argument("-o", "--out", required=True)
    p.set_defaults(func=build)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
