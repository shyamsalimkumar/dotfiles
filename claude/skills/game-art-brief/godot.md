# Godot 4: tiles, collisions, autotile

Give the user these steps; they are editor clicks, not files you can safely write.

## Tile map

1. Draw tiles at the brief's `tile_size` on one sheet (the `pixel-art` skill renders a `.pix` with one `tiles_<n>` frame per tile).
2. Add a `TileMapLayer` node. In the Inspector, Tile Set > New TileSet; set Tile Size to `tile_size`.
3. Open the TileSet panel (bottom), drag the sheet in, answer **Yes** to "automatically create tiles in the atlas".
4. Paint in the TileMap panel. A tile map is faster to build and to run than many `Sprite2D` nodes.

## Collisions

1. Select the `TileMapLayer`, open its TileSet in the Inspector, unfold Physics Layers, Add Element.
2. In the TileSet panel select the solid tiles, Paint > Physics Layer 0, press **F** for a full-tile rectangle, or draw a custom shape for slopes and odd shapes.

## Autotile (terrains)

1. TileSet in the Inspector > Terrain Sets > Add Element, then add one or more Terrains inside it.
2. TileSet panel > Paint > Terrains: pick the terrain set, then on each tile mark the edges/corners that connect to the same terrain.
3. TileMap panel > Terrains tab: pick the terrain and paint; Godot picks edge and corner tiles. This needs a full set of edge and corner tiles (a 3x3 blob plus inner corners at least).

## Beyond frame loops

`AnimationPlayer` keyframes any property (position, modulate, hitboxes) alongside sprite frames; use it when a plain SpriteFrames loop is not enough.
