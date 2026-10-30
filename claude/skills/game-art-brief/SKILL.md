---
name: game-art-brief
description: 'Settle a game''s art rules once (engine, perspective, sprite and tile size, palette, outlines, animations, licenses) by asking the user only what the project doesn''t already answer, and save them to art/ART_BRIEF.md; also imports finished sprite sheets into Godot. Use before making any game art (sprites, characters, enemies, tiles, sprite sheets, pixel art, LPC characters) when art/ART_BRIEF.md is missing, whenever the pixel-art or lpc-character skill starts without a brief, or when the user says "art brief", "art style", "change the art style", "set up game art" or "import this sprite sheet into Godot". Works offline.'
argument-hint: "[what the art is for]"
---

# Game art brief

Every sprite in a game must follow one set of rules (same perspective, size, palette, outline style), or the game looks like several artists made it. This skill decides those rules once, with the user, and writes them down. The `pixel-art` and `lpc-character` skills read the brief and never re-ask.

`SKILLS` below means the directory holding this skill's folder (`~/.claude/skills`). Scripts need only `python3` with Pillow; no network.

## 1. Look before asking

1. Project root: `git rev-parse --show-toplevel`, else the cwd.
2. If `art/ART_BRIEF.md` exists, read it. If it answers everything the current request needs, stop here and hand back to the calling skill. Ask only about a missing field, or when the user asked to change the style.
3. Detect, do not ask:
   - engine: `project.godot` = godot; `ProjectSettings/` + `Assets/` = unity; otherwise ask.
   - existing art: `ls art/ assets/ 2>/dev/null`; the size of existing sprites (`python3 -c "from PIL import Image; print(Image.open('<png>').size)"`) and any `*.hex` palette fix those fields.
   - anything the user already said in this conversation or in `$ARGUMENTS`.
4. If `$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Project Ideas/Project ideas` has a design note on this project's art (`<Project> - Art*.md`), read it; it outranks defaults.

## 2. Ask what is left

Use `AskUserQuestion`: one call, at most 4 questions, recommended option first with "(Recommended)", one line of context per option so the user can pick fast. If more than 4 fields are open, ask the 4 that matter most, use the defaults below for the rest, and say so. Never ask about a field that step 1 settled.

| Field | Options (default first) | Context to give |
| --- | --- | --- |
| source | hand-drawn pixel art / LPC parts / both | LPC: no drawing, fast, 64x64 RPG look, must credit artists. Pixel art: any size, own look, slower. Both: only if sizes match (LPC chars with 32px tiles) |
| perspective | top-down / side-on | Never change mid-project. LPC is top-down, 4 directions |
| sprite size | 16x16 / 32x32 / 64x64 | 16 is quick and still animates well; LPC frames are always 64x64 |
| palette | sweetie-16 / endesga-32 / pico-8 / own `.hex` | Small palette (16-32) looks intentional. Lospec `.hex` files work. LPC uses its own colors |
| outline | dark outline on everything / none | Same rule for every sprite, player and enemies alike |
| animations | idle + walk (4 directions) / + attack + hurt / static only | Each one is more frames to make |
| licenses (LPC only) | any (credit everyone) / DRM-safe only | DRM-safe (CC0, OGA-BY) is safest for Steam, consoles and app stores |

## 3. Write `art/ART_BRIEF.md`

Exactly this format, so other skills can read it cheaply (keep any hand-added notes when refreshing):

```markdown
# Art brief

engine: godot            # godot | unity | other
perspective: top-down    # top-down | side-on
source: pixel-art        # pixel-art | lpc | both
sprite_size: 16x16       # lpc: 64x64
tile_size: 16
palette: sweetie-16      # bundled name or path to a .hex
max_colors: 16
outline: 0               # palette index of the outline color, or none
animations: idle, walk(4 dir)
lpc_licenses: any        # any | drm-safe   (lpc only)
art_dir: art/
notes: <mood, references, light from top-left, anything else agreed>
```

Bundled palettes: `python3 SKILLS/pixel-art/scripts/pixel.py palette`.

Then tell the user the brief in two lines and hand back to the skill that called this one (or suggest `pixel-art` / `lpc-character`).

## 4. Import into the engine (any sprite sheet)

Both art skills write `<name>.png` plus `<name>.json` (frame size and animations). To use one:

- **Godot**: `python3 SKILLS/game-art-brief/scripts/sprites.py godot <sheet.png>`. It writes `<name>_frames.tres` (a SpriteFrames resource) and sets Project Settings > Rendering > Textures > Default Texture Filter to Nearest; without that, Godot blurs pixel art. Tell the user: add an `AnimatedSprite2D`, set Sprite Frames to the `.tres`. Static art: `Sprite2D`, texture = the PNG, Region to pick one frame. For tile maps, collisions or autotile, read [godot.md](godot.md) first.
- **Unity**: read [unity.md](unity.md) and give the user those steps.
- **Other**: hand over the PNG and JSON; the JSON says where each frame is.

Other shared tools in `sprites.py`: `preview` (frames at 1x, zoomed, and as silhouettes; Read the PNG it writes to look) and `outline --color <hex>` (add a 1px outline to every frame).
