extends MeshInstance3D

@onready var _camera := get_viewport().get_camera_3d()
var _mesh := ImmediateMesh.new()


class LineInfo:
	var time_alive: float
	var lifetime: float

	var p1: Vector3
	var p2: Vector3
	var c1: Color
	var c2: Color


var _lines: Array[LineInfo] = []


func _init():
	mesh = _mesh

	var mat := StandardMaterial3D.new()
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	material_override = mat

	# Should process after everything
	process_priority = 500


func draw_marker(pos: Vector3, color: Color, lifetime: float = 0.0, size: float = 0.05):
	var cam_basis := _camera.global_transform.basis
	var cam_x := cam_basis.x
	var cam_y := cam_basis.y

	draw_line(
		pos + size * (cam_x + cam_y),
		pos + size * (-cam_x - cam_y),
		color,
		null,
		lifetime
	)

	draw_line(
		pos + size * (-cam_x + cam_y),
		pos + size * (cam_x - cam_y),
		color,
		null,
		lifetime
	)


# TODO: c2 - static type?
func draw_line(p1: Vector3, p2: Vector3, c1: Color, c2 = null, lifetime: float = 0.0):
	if not c2:
		c2 = c1

	var line_info := LineInfo.new()
	line_info.lifetime = lifetime
	line_info.p1 = p1
	line_info.p2 = p2
	line_info.c1 = c1
	line_info.c2 = c2

	_lines.append(line_info)


func _draw_lines(delta: float) -> bool:
	if _lines.size() == 0:
		return false

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in range(_lines.size() - 1, -1, -1):
		var line_info := _lines[i]

		line_info.time_alive += delta
		if line_info.time_alive >= line_info.lifetime:
			_lines.remove_at(i)

		_mesh.surface_set_color(line_info.c1)
		_mesh.surface_add_vertex(line_info.p1)
		_mesh.surface_set_color(line_info.c2)
		_mesh.surface_add_vertex(line_info.p2)

	_mesh.surface_end()

	return true


func _process(delta: float):
	_mesh.clear_surfaces()
	_draw_lines(delta)
