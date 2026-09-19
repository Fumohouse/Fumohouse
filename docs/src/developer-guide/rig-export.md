# Rig export/import procedure

The fumo rig is exported in two passes: one without animations, and one with
animations. This ensures the entire rig model does not need to be updated for
every animation update (thus only when the armature or meshes change),
minimizing large files put into source control.

## Export and import without animations

1. Select the armature and all of the meshes in the scene view.
1. Export as `.glb` (without animations):
   1. Under Operator Presets, select Restore Operator Defaults.
   1. Use the following settings (if not mentioned, use defaults):
      - Limit to: Selected Objects
      - Animation: Deselect
   1. Import this file into Godot as the main rig. Verify there are no
      animations present.

## Export and import with animations

1. Select the armature, all meshes, and all actions (in the NLA timeline).
1. Export as `.glb` (with animations):
   1. Under Operator Presets, select Restore Operator Defaults.
   1. Use the following settings (if not mentioned, use defaults):
      - Limit to: Selected Objects
   1. Import this file into Godot as a throwaway file. Animations should be
      present.
1. Open the throwaway file in Godot as a scene.
1. Navigate to the AnimationPlayer.
1. Click Animation, then Manage Animations.
1. Click the save icon on the [Global] animation library.
1. For every new or updated animation, press the save icon and Save As, with a
   filename matching the animation name, to a `.tres` file.
1. Delete the throwaway file.
1. Open the character scene in `@fumohouse/fumo`.
1. Navigate to the rig's AnimationPlayer.
1. Click Animation, then Manage Animations.
1. For every new animation, click the folder icon and select its `.tres` file.
