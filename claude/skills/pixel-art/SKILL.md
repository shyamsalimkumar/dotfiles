---
name: pixel-art
description: 'Draw original pixel-art sprites, animations, items and tile sets for a game, offline: write each sprite as a small text grid, lint it (palette, doubles, outline consistency), render it to a PNG sprite sheet, look at it at real size, and import it into Godot or Unity. Use when the user asks to draw, make or fix pixel art, a sprite, a tile set, an icon, a walk cycle or other game art by hand, or says "pixel art", "Aseprite-style", "16x16 sprite". For characters built from ready-made parts with no drawing, use lpc-character instead.'
argument-hint: "[what to draw]"
---

# Pixel art

You draw by writing a `.pix` text file: one character per pixel. A script turns it into a sprite sheet. This keeps the work offline and cheap: edit a few characters, re-render, never regenerate whole images.

`SKILLS` below means `~/.claude/skills`. In commands, `pixel.py` means `python3 SKILLS/pixel-art/scripts/pixel.py` (`palette`, `check`, `render`) and `sprites.py` means `python3 SKILLS/game-art-brief/scripts/sprites.py` (`preview`, `outline`, `godot`).

## 1. Get the rules

1. Read `art/ART_BRIEF.md` at the project root. If it is missing, run the `game-art-brief` skill first and come back. Use its size, palette, outline, perspective and animations; do not re-ask them.
2. If the request does not say what to draw or which poses/animations, ask with `AskUserQuestion` (one call, at most 3 questions, recommended option first). A clear request needs no questions.

## 2. The `.pix` file

Put it at `art/<name>.pix` (the brief's `art_dir`). Print the palette with its index characters first: `pixel.py palette <palette>`.

```
palette: sweetie-16     # from the brief
size: 16x16             # from the brief
outline: 0              # brief's outline index; omit if outline: none
fps: 8
=== idle_0
................
.....000000.....
```

- `.` is transparent; `0-9`, `a-z`, `A-Z` are palette indexes (`a` = 10).
- Every frame is a block `=== <animation>_<n>`, exactly `size` rows of `size` columns. Same-animation frames become one sheet row, in file order.
- Directional animations: `walk_down_0`... `walk_up_0`... (top-down) or `run_0`... facing right (side-on; the engine flips it).
- Tiles: one `tiles_<n>` frame per tile.

## 3. Draw (in this order)

1. **Silhouette first.** Write frame 0 as one solid color only. Render and preview (step 4). If the shape does not read clearly at 1x, fix the shape before any detail. Shape matters more than detail at this size.
2. **Then detail**, within the silhouette:
   - Every pixel on purpose. Use each material's colors as a dark-to-light ramp; keep one light direction (top-left unless the brief says otherwise).
   - Contrast: colors opposite on the color wheel make things pop (player vs ground); neighbors make harmony. Don't pick colors at random.
   - Lines: no **doubles**. On diagonals and curves, pixels touch only at corners, never in L-shaped clumps.
   - Outline: exactly as the brief says, on every sprite. Never outline some sprites and not others.
3. **Animate** by copying the frame and changing few pixels. Keep the feet/anchor still between frames. Usual counts: idle 2-4 frames, walk 4 per direction, hit/hurt 2-3.

## 4. Check, render, look

1. `pixel.py check art/*.pix --max-colors <max_colors>`. Pass every `.pix` in the game, so outline consistency is checked across sprites. Fix everything it reports; it must say `ok`.
2. `pixel.py render art/<name>.pix` writes `art/<name>.png` + `art/<name>.json`.
3. `sprites.py preview art/<name>.png` (add `--anim <regex>` to show only what changed), then Read the preview PNG. Left: 1x, how the player sees it; middle: zoomed; right: silhouette. Judge it from the 1x and silhouette views. Fix and repeat until it reads well.

Token rules: change frames with the Edit tool, never rewrite the whole file; preview only the animations you changed; do not Read the full-size sheet.

## 5. Hand over

1. Import: `sprites.py godot art/<name>.png` for Godot, else follow `game-art-brief`'s import section.
2. Tell the user: files written, frame size, animation names, and the one editor step left (e.g. "add an AnimatedSprite2D and set Sprite Frames to `art/<name>_frames.tres`").
3. Keep the `.pix` file; it is the source to edit later.
