import bpy

bl_info = {
    "name": "Fumohouse",
    "author": "voided_etc",
    "description": "Fumohouse Blender addon, companion to the Godot addon found at addons/fumohouse.",
    "blender": (3, 2, 1),
    "version": (0, 0, 1),
    "category": "Generic"
}


class SCENE_OT_copy_transforms(bpy.types.Operator):
    bl_idname = "scene.copy_transforms"
    bl_label = "Copy Scene Transforms"

    def execute(self, context):
        transform_strs = []

        for obj in context.scene.objects:
            if not obj.visible_get(view_layer=context.view_layer):
                continue

            # Good luck reading this :)
            transform_str = "\"" + obj.name.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
            transform_str += "(" + ",".join([",".join([str(val) for val in row]) for row in obj.matrix_world]) + ")"
            transform_strs.append(transform_str)

        context.window_manager.clipboard = "\n".join(transform_strs)

        return { "FINISHED" }


class VIEW3D_PT_fumohouse_panel(bpy.types.Panel):
    bl_label = "Fumohouse"
    bl_category = "Scene"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"

    def draw(self, context):
        self.layout.operator("scene.copy_transforms", text="Copy Scene Transforms", icon="COPYDOWN")


classes = (
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
