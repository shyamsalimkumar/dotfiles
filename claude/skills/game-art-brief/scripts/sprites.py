#!/usr/bin/env python3
"""Offline sprite-sheet tools shared by the pixel-art and lpc-character skills.

Every sheet comes with a JSON file next to it (same stem):

    {"image": "hero.png", "frame": [16, 16],
     "animations": {"walk_down": {"row": 0, "cols": [0, 1, 2, 3], "fps": 8, "loop": true}}}
"""
import argparse
import json
import re
import sys
from pathlib import Path

from PIL import Image


def load_sheet(png):
    png = Path(png)
    meta_path = png.with_suffix(".json")
    if not meta_path.exists():
        sys.exit(f"{meta_path} missing: every sheet needs its JSON (see --help)")
    return Image.open(png).convert("RGBA"), json.loads(meta_path.read_text())


def preview(args):
    """One small image to look at: frames at 1x (how the player sees them),
    scaled up, and as solid silhouettes (is the shape readable?)."""
    sheet, meta = load_sheet(args.png)
    fw, fh = meta["frame"]
    anims = list(meta["animations"].items())
    if args.anim:
        anims = [a for a in anims if re.search(args.anim, a[0])]
    anims = anims[: args.max_rows]
    cols = min(args.max_cols, max(len(a["cols"]) for _, a in anims))
    s, gap = args.scale, 2
    width = cols * fw * (1 + s + s) + gap * 3
    out = Image.new("RGBA", (width, len(anims) * (fh * s + gap)), (200, 200, 200, 255))
    for r, (_, a) in enumerate(anims):
        y = r * (fh * s + gap)
        for c, col in enumerate(a["cols"][:cols]):
            frame = sheet.crop((col * fw, a["row"] * fh, (col + 1) * fw, (a["row"] + 1) * fh))
            sil = Image.new("RGBA", frame.size, (0, 0, 0, 255))
            sil.putalpha(frame.getchannel("A").point(lambda v: 255 if v else 0))
            out.alpha_composite(frame, (c * fw, y))
            x2 = cols * fw + gap
            out.alpha_composite(frame.resize((fw * s, fh * s), Image.NEAREST), (x2 + c * fw * s, y))
            x3 = x2 + cols * fw * s + gap
            out.alpha_composite(sil.resize((fw * s, fh * s), Image.NEAREST), (x3 + c * fw * s, y))
    dest = Path(args.out or Path(args.png).with_name(Path(args.png).stem + "_preview.png"))
    out.save(dest)
    print(f"wrote {dest} ({out.width}x{out.height}); rows: {', '.join(n for n, _ in anims)}")


def outline(args):
    """Add a 1px outline around every opaque shape, inside each frame."""
    sheet, meta = load_sheet(args.png)
    color = tuple(int(args.color.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    alpha = sheet.getchannel("A").load()
    fw, fh = meta["frame"]
    px = sheet.load()
    added = 0
    for y in range(sheet.height):
        for x in range(sheet.width):
            if alpha[x, y]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                same_frame = nx // fw == x // fw and ny // fh == y // fh
                if same_frame and 0 <= nx < sheet.width and 0 <= ny < sheet.height and alpha[nx, ny]:
                    px[x, y] = color
                    added += 1
                    break
    dest = Path(args.out or args.png)
    sheet.save(dest)
    if dest.with_suffix(".json") != Path(args.png).with_suffix(".json"):
        dest.with_suffix(".json").write_text(json.dumps({**meta, "image": dest.name}, indent=2) + "\n")
    print(f"wrote {dest}: {added} outline pixels")


def godot_project(start):
    for d in [start, *start.parents]:
        if (d / "project.godot").exists():
            return d
    sys.exit(f"no project.godot above {start}: put the sheet inside the Godot project first")


def set_nearest_filter(project_file):
    """Project Settings > Rendering > Textures > Default Texture Filter = Nearest.
    Without it Godot blurs pixel art."""
    text = project_file.read_text()
    key = "textures/canvas_textures/default_texture_filter"
    if re.search(rf"^{re.escape(key)}=0\s*$", text, re.MULTILINE):
        return False
    text = re.sub(rf"^{re.escape(key)}=.*\n?", "", text, flags=re.MULTILINE)
    if re.search(r"^\[rendering\]\s*$", text, re.MULTILINE):
        text = re.sub(r"^\[rendering\]\s*$", f"[rendering]\n\n{key}=0", text, count=1, flags=re.MULTILINE)
    else:
        text = text.rstrip("\n") + f"\n\n[rendering]\n\n{key}=0\n"
    project_file.write_text(text)
    return True


def godot(args):
    """Write a SpriteFrames .tres (for AnimatedSprite2D) next to the sheet."""
    png = Path(args.png).resolve()
    _, meta = load_sheet(png)
    root = godot_project(png.parent)
    fw, fh = meta["frame"]
    subs, anims = [], []
    for name, a in meta["animations"].items():
        frames = []
        for col in a["cols"]:
            sid = f"AtlasTexture_{len(subs)}"
            subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("1")\n'
                        f"region = Rect2({col * fw}, {a['row'] * fh}, {fw}, {fh})\n")
            frames.append(f'{{\n"duration": 1.0,\n"texture": SubResource("{sid}")\n}}')
        anims.append(f'{{\n"frames": [{", ".join(frames)}],\n"loop": {str(a.get("loop", True)).lower()},\n'
                     f'"name": &"{name}",\n"speed": {float(a.get("fps", 8))}\n}}')
    res_path = "res://" + png.relative_to(root).as_posix()
    tres = (f'[gd_resource type="SpriteFrames" load_steps={len(subs) + 2} format=3]\n\n'
            f'[ext_resource type="Texture2D" path="{res_path}" id="1"]\n\n'
            + "\n".join(subs) + f"\n[resource]\nanimations = [{', '.join(anims)}]\n")
    dest = png.with_name(png.stem + "_frames.tres")
    dest.write_text(tres)
    changed = set_nearest_filter(root / "project.godot")
    print(f"wrote {dest.relative_to(root)} ({len(anims)} animations)"
          + ("; set default texture filter to Nearest in project.godot" if changed else ""))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("preview", help="1x + scaled + silhouette view of a sheet")
    p.add_argument("png")
    p.add_argument("-o", "--out")
    p.add_argument("--scale", type=int, default=4)
    p.add_argument("--anim", help="regex: only animations whose name matches")
    p.add_argument("--max-rows", type=int, default=4)
    p.add_argument("--max-cols", type=int, default=8)
    p.set_defaults(func=preview)
    p = sub.add_parser("outline", help="add a 1px outline to every frame")
    p.add_argument("png")
    p.add_argument("--color", required=True, help="hex, e.g. #1a1c2c")
    p.add_argument("-o", "--out", help="default: overwrite the input")
    p.set_defaults(func=outline)
    p = sub.add_parser("godot", help="write <sheet>_frames.tres and set Nearest filtering")
    p.add_argument("png")
    p.set_defaults(func=godot)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
