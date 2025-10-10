# Character export and import procedure

To enable character customization and allow mesh reuse in future character
models, characters should be exported in many parts: at least as many as
according to the [part
breakdown](../design/core/@fumohouse-fumo.md#part-breakdown), and further
breaking down when appropriate.

Additionally, to make the meshes maintainable in the future, all destructive
changes should be made to a copy (see the collections in the Blender template
dedicated to export).

## Preparation for export

1. If applicable, convert copies of non-meshes (e.g., paths) to meshes. Combine
   small, unusable parts (e.g., hair strands) into one object.
1. For objects that have the same mesh but different transforms, make a copy and
   export only the copy. Keep the original duplicates in place so their
   transforms can be copied on import.
   - This does not apply to mirror copies, unless your mirror can be done using
     a rotation (i.e., the object is rotationally symmetric).
   - If you mirrored an object (e.g., using negative scale) that is rotationally
     symmetric, then convert its mirror into a rotation. Using a mirror will
     result in unnecessary duplicated mesh data.
   - For example, `doremy_lsleeve` and `doremy_rsleeve` share the same mesh but
     use different rotations. They are exported only once as `doremy_sleeve`.
1. If applicable, apply all modifiers (and rotation/scale as necessary) on
   copies of the original objects.
   - If your mesh is mirrored, it may have a negative scale. The negative scale
     must be applied and the normals fixed before export: see [Blender
     tips](./blender-tips.md).
1. Ensure that the origin of all objects to export makes sense.
1. Name all the objects to be exported according to the `snake_case` convention:
   `character_part_name` or `any_generic_part_name` for generic parts not
   specific to the character.

## Export procedure

1. Ensure that the Fumohouse Blender addon is installed. The addon is present in
   the main Fumohouse repository at `misc/fumohouse_blender`. This addon is used
   to make the export and import process much faster.
1. **Take a backup of the Blender file. The export step is technically
   destructive as it reverts transforms on all selected objects.** Although the
   transforms will be restored, make sure to either save the file now and close
   without saving after export, or save a dedicated backup, especially if
   anything goes wrong.
1. Select all of the objects that you want to export.
1. Open the right-hand side viewport menu (N) and go to the Scene tab. In the
   Fumohouse panel, click Export Meshes.
1. Each mesh will be exported as `.glb` individually as if translation, scale,
   and rotation are all removed. Each file will be named after the name of the
   object. The export folder is named `fumohouse_export_TIMESTAMP` and will be
   opened when the process is complete.

## Import procedure

1. Import all of the exported meshes into Godot in the `@fumohouse/fumo_models`
   module. Place the files into `assets/generic` (for generic assets) and
   `assets/character_name` (for character-specific assets).
1. Edit all import configurations to use this file as the import script:
   `res://addons/@fumohouse/common/resources/materials/post_import_ext.gd` and
   reimport the models.
1. If any textures are extracted more than once, make them into a common
   material and select it as external in the import settings. Set Embedded Image
   to Discard All Textures in the import settings.
1. Create a new temporary scene inherited from
   `res://addons/@fumohouse/fumo/fumo.tscn`.
1. Add all of the imported parts to the scene. For objects that have the same
   mesh but different transforms, make duplicates of the imported mesh. **Name
   all of the nodes the same as they are in Blender.**
1. Open the character in Blender and select all meshes (or all meshes that are
   part of the character).
1. Go to the Fumohouse panel and click Copy Scene Transforms.
1. Select all of the character part nodes in Godot.
1. Open the Character Appearance dock in Godot (a tab on the right). Click Paste
   Scene Transforms.
1. The meshes may be grouped into scenes that are attached to one bone of the
   character. Make these groups using `Node3D`s in Godot, then save them as
   scenes (named using the same naming convention as the meshes). For example,
   all of the parts attached to Doremy's torso, consisting of 4 main dress parts
   and 46 pom poms, can be grouped into one scene called `doremy_torso`.
1. For meshes that have options (e.g., color), make them into an inherited
   scene and add an appropriate customization script.
1. Open the Appearance node in the character scene, which contains all of the
   bone attachments. Move every part node into the appropriate bone attachment.
   For example, hats should be moved to the Head attachment, and sleeves should
   go into LArm/RArm.
1. In the Character Appearance pane, enter the target folder for all character
   resources:
   `res://addons/@fumohouse/fumo_models/resources/part_data/character_name`.
1. Press Save Appearance Data to .tres. This will create `.tres` files for every
   node under each bone attachment, named after the node name.
1. Go to the save folder.
1. Group the parts together into the smallest part to show in the character
   editor. For example, Doremy's shoes are made of the main shoe mesh and two
   pom poms. These six (three for left and right) initially each have their own
   `SinglePart`. Create a new `MultiPart` to group all such parts together, and
   add the `SinglePart`s as members. Click the dropdown on each one and click
   Make Unique, then delete the original `SinglePart` files.
1. Set an appropriate ID, name, scope, and default options for all of the
   remaining part resource files.
1. Ensure that the parts are correctly configured using the character editor.
1. Delete the character scene.
1. Create an appearance resource for the character under
   `res://addons/@fumohouse/fumo_models/resources/presets`.

Congratulations, you're done!
