class_name SingleColorCustomizer
extends PartCustomizer
## A part customizer that changes the color of one material.

## The meshes to apply the color to.
@export var meshes: Array[MeshInstance3D]

## A one-to-one mapping with [member meshes] indicating which config parameter
## to use for the color. If this array is shorter than [member meshes], the last
## entry is used for the remaining meshes.
@export var attributes: PackedStringArray = ["color"]

## The material index to customize.
@export var material_index := 0


func _update(config: Dictionary):
	for i in meshes.size():
		var mesh := meshes[i]
		var attribute := StringName(
			attributes[i] if i < attributes.size() else attributes[attributes.size() - 1]
		)
		var color: Color = config.get(attribute, Color.WHITE)
		var material := mesh.get_active_material(material_index)

		if material is StandardMaterial3D:
			material.albedo_color = color
		elif material is ShaderMaterial:
			if material.get_shader_parameter("recolor") != null:
				material.set_shader_parameter("recolor", color)
				if material.get_shader_parameter("albedo") != null:
					material.set_shader_parameter("albedo", Color.WHITE)
			elif material.get_shader_parameter("albedo") != null:
				material.set_shader_parameter("albedo", color)
