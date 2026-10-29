---
name: lpc-character
description: 'Build animated, game-ready 64x64 characters, NPCs and monsters with no drawing, by stacking Universal LPC (Liberated Pixel Cup) parts offline: bodies, heads (human, orc, goblin, skeleton, wolf, zombie...), hair, armour, clothes, weapons, shields, wings and tails, recolored and composited into a standard LPC sprite sheet with walk, idle, attack and hurt animations, plus the credits file the licenses require. Use when the user wants characters or enemies "without drawing", lots of character variations, RPG or top-down character sprites fast, or mentions LPC, Liberated Pixel Cup or the Universal LPC Spritesheet Character Generator.'
argument-hint: "[character idea]"
---

# LPC character

The Universal LPC generator is a website that stacks pre-drawn parts into one sprite sheet. This skill does the same offline with `python3 SKILLS/lpc-character/scripts/lpc.py`, reading the generator's own data. `SKILLS` below means `~/.claude/skills`; in commands, `lpc.py` means `python3 SKILLS/lpc-character/scripts/lpc.py`.

## 1. Setup and rules

1. If `~/.cache/lpc-generator/sheet_definitions` is missing, run `SKILLS/lpc-character/scripts/setup.sh` once (needs internet, ~500 MB). If there is no internet, say so and stop.
2. Read `art/ART_BRIEF.md` at the project root. If it is missing, run the `game-art-brief` skill first. Take `animations`, `lpc_licenses` and `art_dir` from it. LPC frames are 64x64 and top-down; if the brief says otherwise, tell the user the art will not match before going on.
3. If the user did not describe the character, ask with `AskUserQuestion` (one call, at most 4 questions, recommended first): what it is (hero, enemy kind), body type (male, female, muscular, teen, child), gear level (none, cloth, leather, steel), weapon/shield. Skip anything they said.

## 2. Pick parts

```bash
lpc.py types                                # part types, e.g. head(45) hair(91) wings(11)
lpc.py find orc --type head                 # id | type | name | colors | licenses
lpc.py find steel --type armour --body male --drm-safe
lpc.py show heads_orc_male                  # body types, animations, colors, credits
lpc.py colors metal                         # color names: body, cloth, hair, metal, wood, eye, all
```

- A character is: `body`, one `head`, then any of hair, expression, clothes, armour (`torso_armour_*`, `arms_armour`, `legs_armour`, `feet_armour`), hat, shield, weapon, wings, tail, shadow.
- Use only parts whose `show` lists the brief's animations and the chosen body type; a part without art for an animation leaves it blank there.
- `lpc_licenses: drm-safe` in the brief: add `--drm-safe` to `find` and `build`.

## 3. Build

```bash
lpc.py build -b male body:green heads_orc_male torso_armour_plate:steel arms_armour:steel \
  legs_armour:steel feet_armour:steel shield_crusader --anims walk,idle,hurt -o art/characters/orc_crusader.png
```

- `id:color` picks a color (a variant name, or a palette color like `olive` / `lpcr.ivory`); `id:c1,c2` for two-color parts. Heads, ears and noses take the body's color when given none.
- `--anims` from the brief (names: spellcast thrust walk slash shoot hurt climb idle jump sit emote run combat 1h_backslash 1h_halfslash).
- Output: `<name>.png` (832 px wide, 13 frames per row, rows up/left/down/right per animation), `<name>.json` (frames per animation + the recipe under `lpc`) and `<name>_CREDITS.csv`.
- Fix every `warning:` line: swap the part, or tell the user what stays blank.

## 4. Look

`python3 SKILLS/game-art-brief/scripts/sprites.py preview art/characters/<name>.png --scale 1 --max-cols 4 --anim 'walk_(down|left)'`, then Read the preview. Check for clipping (wings through a shield, a cape through armour) and that the silhouette reads. Swap clashing parts and rebuild.

Many variations (an enemy army): change colors and one or two parts per build, one command each. Do not preview every one; preview one per new part combination.

## 5. Credits (required)

LPC art is free only if every artist is credited (CC0 parts excepted). Keep each `<name>_CREDITS.csv` next to its sheet, never delete it, and tell the user the game must show these credits (a credits screen or a visible link). CC-BY-SA parts also require sharing changed versions of that art under CC-BY-SA.

## 6. Hand over

1. Import: `python3 SKILLS/game-art-brief/scripts/sprites.py godot art/characters/<name>.png` for Godot (animation names like `walk_down`), else follow `game-art-brief`'s import section.
2. Optional, only if the brief asks for extra pop on busy backgrounds: `sprites.py outline <png> --color <hex>`.
3. Tell the user: files written, animation names, licenses line, the credits rule, and the rebuild command (the recipe is in the JSON).
