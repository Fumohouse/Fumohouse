class_name SingleColorCustomizer
extends PartCustomizer
## A part customizer that changes the color of one material.

## The mesh to apply the color to.
@export var mesh: MeshInstance3D

## The material index to customize.
@export var material_index := 0


func _update(config: Dictionary):
	assert(mesh != null, "A mesh is required to customize the color.")
	assert(config.has(&"color"), "color is a required key in the part configuration.")

	var color: Color = config.get(&"color") if config.has(&"color") else Color.WHITE
	var material := mesh.get_active_material(material_index)

	if material is StandardMaterial3D:
		material.albedo_color = color
	elif material is ShaderMaterial:
		if material.get_shader_parameter("albedo") != null:
			material.set_shader_parameter("albedo", color)
