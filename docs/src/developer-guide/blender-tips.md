# Blender tips

Miscellaneous tips for Blender users:

- Godot is -Z forward, Blender is +Y forward. Model things so that +Y is forward
  in Blender so that it will face the correct direction in Godot.
- If you see broken lighting (i.e., unusually dark faces) in Godot:
  - Negative scale (e.g., resulting from mirroring) in Blender is not acceptable
    for Godot exports as it breaks normals. First apply the scale (Ctrl-A, S)
    and correct the normals (enter Edit mode, A, Shift-N) in Blender, then
    export to Godot.
