@tool
extends EditorScenePostImport
## Post import script for converting imported materials to an extended
## version of [StandardMaterial3D] that includes dither alpha and dissolve
## components.

const BASE_MAT: ShaderMaterial = preload("extended_standard_material.tres")

const PROPERTY_MAP: Dictionary[String, String] = {
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
	"uv2_offset": "uv2_offset",
	"uv2_scale": "uv2_scale",
}

const TEXTURE_MASKS: Array[Vector4] = [
	Vector4(1, 0, 0, 0),
	Vector4(0, 1, 0, 0),
	Vector4(0, 0, 1, 0),
	Vector4(0, 0, 0, 1),
	Vector4(0.3333333, 0.3333333, 0.3333333, 0),
]

var _converted_materials: Dictionary[Object, ShaderMaterial] = {}


func _post_import(scene: Node) -> Object:
	_iterate(scene)
	return scene


func _iterate(node: Node):
	for child in node.get_children():
		_iterate(child)

	if node is not MeshInstance3D:
		return

	var mesh_inst := node as MeshInstance3D
	var mesh: Mesh = node.mesh

	for i in range(mesh.get_surface_count()):
		var material := mesh.surface_get_material(i)
		if material is StandardMaterial3D:
			mesh_inst.set_surface_override_material(
					i,
					_convert_material(material as StandardMaterial3D)
			)
		else:
			mesh_inst.set_surface_override_material(i, material)


func _convert_material(mat: StandardMaterial3D) -> ShaderMaterial:
	if _converted_materials.has(mat):
		return _converted_materials[mat]

	var new_mat := BASE_MAT.duplicate() as ShaderMaterial

	for key in PROPERTY_MAP.keys():
		new_mat.set_shader_parameter(PROPERTY_MAP[key], mat.get(key))

	new_mat.set_shader_parameter(
			"ao_texture_channel", TEXTURE_MASKS[mat.ao_texture_channel])

	new_mat.set_shader_parameter(
			"metallic_texture_channel",
			TEXTURE_MASKS[mat.metallic_texture_channel])

	new_mat.resource_local_to_scene = true

	_converted_materials[mat] = new_mat
	return new_mat
