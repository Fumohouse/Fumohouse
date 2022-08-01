extends Node3D


@export var default_color := Color.WHITE
@export_node_path(MeshInstance3D) var mesh: NodePath
var _mesh: MeshInstance3D


func _ready():
	_update_mesh()


func _fh_initialize(config: Dictionary):
	if not _mesh:
		push_warning("This single colored part has no linked mesh.")
		return

	var material = _mesh.get_active_material(0)
	if not (material is StandardMaterial3D):
		return

	(material as StandardMaterial3D).albedo_color = \
			config.color \
			if config.has("color") \
			else default_color


func _update_mesh():
	if not is_inside_tree():
		return

	if not mesh.is_empty():
		_mesh = get_node(mesh) as MeshInstance3D
