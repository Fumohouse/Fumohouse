import bpy
import mathutils
import time
from pathlib import Path
import sys
import os
import subprocess

bl_info = {
    "name": "Fumohouse",
    "author": "voided_etc",
    "description": "Fumohouse Blender addon, companion to Godot tooling.",
    "blender": (3, 2, 1),
    "version": (0, 0, 1),
    "category": "Generic"
}


class SCENE_OT_export(bpy.types.Operator):
    """Export all selected, visible meshes as .glb, ignoring the transform."""

    bl_idname = "scene.fumohouse_export"
    bl_label = "Export Meshes"

    def execute(self, context):
        selection = list(context.selected_objects)
        if len(selection) == 0:
            return { "FINISHED" }

        bpy.ops.object.select_all(action="DESELECT")

        out_path = Path(bpy.data.filepath).parent / f"fumohouse_export_{int(time.time())}"
        os.mkdir(out_path)

        for obj in selection:
            if not obj.visible_get(view_layer=context.view_layer):
                continue

            old_transform = obj.matrix_world.copy()
            try:
                # Reset all transforms
                obj.matrix_world = mathutils.Matrix()
                obj.select_set(True)

                bpy.ops.export_scene.gltf(
                    filepath=str(out_path / f"{obj.name}.glb"),
                    export_format="GLB",
                    use_selection=True,
                )
            finally:
                # Restore transforms
                obj.matrix_world = old_transform
                obj.select_set(False)

        # Restore selection
        bpy.ops.object.select_all(action="DESELECT")
        for obj in selection:
            obj.select_set(True)

        if sys.platform == "win32":
            os.startfile(out_path)
        else:
            subprocess.call(["open" if sys.platform == "darwin" else "xdg-open", str(out_path)])

        return { "FINISHED" }


class SCENE_OT_copy_transforms(bpy.types.Operator):
    """Copy the transforms of selected, visible scene objects, for parsing in Godot"""

    bl_idname = "scene.fumohouse_copy_transforms"
    bl_label = "Copy Scene Transforms"

    def execute(self, context):
        transform_strs = []

        for obj in context.selected_objects:
            if not obj.visible_get(view_layer=context.view_layer):
                continue

            transform_str = obj.name + "\t(" + ",".join([",".join([str(val) for val in row]) for row in obj.matrix_world]) + ")"
            transform_strs.append(transform_str)

        context.window_manager.clipboard = "\n".join(transform_strs)

        return { "FINISHED" }


class VIEW3D_PT_fumohouse_panel(bpy.types.Panel):
    bl_label = "Fumohouse"
    bl_category = "Scene"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"

    def draw(self, context):
        self.layout.operator("scene.fumohouse_export", text="Export Meshes", icon="EXPORT")
        self.layout.operator("scene.fumohouse_copy_transforms", text="Copy Scene Transforms", icon="COPYDOWN")


classes = (
    SCENE_OT_export,
    SCENE_OT_copy_transforms,
    VIEW3D_PT_fumohouse_panel,
)


def register():
    for c in classes:
        bpy.utils.register_class(c)


def unregister():
    for c in classes:
        bpy.utils.unregister_class(c)


if __name__ == "__main__":
    register()
