@tool
extends EditorScenePostImport


const _PROPERTY_MAP := {
	"albedo_color": "albedo",
	"albedo_texture": "texture_albedo",
	"ao_light_affect": "ao_light_affect",
	"ao_texture": "texture_ambient_occlusion",
	# ao_texture_channel: special behavior
	"emission": "emission",
	"emission_energy": "emission_energy",
	"metallic": "metallic",
	"metallic_specular": "specular",
	"metallic_texture": "texture_metallic",
	# metallic_texture_channel: special behavior
	"normal_scale": "normal_scale",
	"normal_texture": "texture_normal",
	"roughness": "roughness",
	"roughness_texture": "texture_roughness",
	"uv1_offset": "uv1_offset",
	"uv1_scale": "uv1_scale",
}

var _converted_materials := {}


func _post_import(scene: Node) -> Object:
	_iterate(scene)
	return scene


func _get_texture_mask(channel: BaseMaterial3D.TextureChannel):
	const MASKS := [
		Plane(1, 0, 0, 0),
		Plane(0, 1, 0, 0),
		Plane(0, 0, 1, 0),
		Plane(0, 0, 0, 1),
		Plane(0.3333333, 0.3333333, 0.3333333, 0),
	]

	return MASKS[channel]


func _convert_material(mat: StandardMaterial3D) -> ShaderMaterial:
	if _converted_materials.has(mat):
		return _converted_materials[mat]

	var new_mat: ShaderMaterial = load("res://resources/materials/gltf_dither_material.tres") \
			.duplicate()

	for key in _PROPERTY_MAP.keys():
		new_mat.set_shader_uniform(_PROPERTY_MAP[key], mat.get(key))

	new_mat.set_shader_uniform("ao_texture_channel", _get_texture_mask(mat.ao_texture_channel))
	new_mat.set_shader_uniform("metallic_texture_channel", _get_texture_mask(mat.metallic_texture_channel))

	new_mat.resource_local_to_scene = true

	_converted_materials[mat] = new_mat
	return new_mat


func _iterate(node: Node):
	if node is MeshInstance3D and node.mesh:
		var mesh: Mesh = node.mesh

		for i in mesh.get_surface_count():
			var material := mesh.surface_get_material(i)
			if material is StandardMaterial3D:
				mesh.surface_set_material(i, _convert_material(material))

	for child in node.get_children():
		_iterate(child)
