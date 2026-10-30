# Unity: importing a sprite sheet

Give the user these steps. Read frame size and animation rows from the sheet's `.json`.

1. Drop the PNG into `Assets/`. In its Import Settings:
   - Texture Type: Sprite (2D and UI); Sprite Mode: Multiple
   - Pixels Per Unit: the brief's `tile_size` (so one tile = one unit)
   - Filter Mode: **Point (no filter)**; Compression: **None** (both stop blur and color smearing)
   - Apply.
2. Sprite Editor > Slice > Type: Grid By Cell Size, cell = the JSON `frame` size (LPC: 64x64) > Slice > Apply.
3. For each animation in the JSON: select its frames (row `row`, columns `cols`) in the Project window and drag them into the Scene; Unity makes an Animation Clip and Animator. Set the clip's sample rate to the JSON `fps`.
4. Camera: use the Pixel Perfect Camera component (URP 2D) with Assets Pixels Per Unit = the same value as step 1.
