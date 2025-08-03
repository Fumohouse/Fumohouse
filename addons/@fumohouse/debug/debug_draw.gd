class_name DebugDraw
extends MeshInstance3D
## 3D debug drawing singleton.


var _mesh := ImmediateMesh.new()
var _lines: Array[LineInfo] = []


static func get_singleton() -> DebugDraw:
	return Modules.get_singleton(&"DebugDraw") as DebugDraw


func _init():
	mesh = _mesh

	var mat := StandardMaterial3D.new()
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	material_override = mat

	# Should process last
	process_priority = 500


func _process(delta: float):
	_mesh.clear_surfaces()
	if _lines.is_empty():
		return

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in range(_lines.size() - 1, -1, -1):
		var ln := _lines[i]

		_mesh.surface_set_color(ln.c1)
		_mesh.surface_add_vertex(ln.p1)
		_mesh.surface_set_color(ln.c2)
		_mesh.surface_add_vertex(ln.p2)

		ln.time_alive += delta
		if ln.time_alive >= ln.lifetime:
			_lines.remove_at(i)

	_mesh.surface_end()


## Draw a line from [param p1] to [param p2]. The color at [param p1] is
## [param c1]. The color at [param p2] is [param c2]. The line stays on screen
## for [param lifetime] seconds, or for one frame if it is zero.
func draw_line(p1: Vector3, p2: Vector3, c1: Color, c2 := c1, lifetime := 0.0):
	var line := LineInfo.new()
	line.lifetime = lifetime
	line.p1 = p1
	line.c1 = c1
	line.p2 = p2
	line.c2 = c2

	_lines.push_back(line)


## Draw an [AABB] [param aabb] with color [param color]. It stays on screen for
## [param lifetime] seconds, or for one frame if it is zero.
func draw_aabb(aabb: AABB, color: Color, lifetime := 0.0):
	var length: Vector3 = Vector3.BACK * aabb.size.z
	var width: Vector3 = Vector3.RIGHT * aabb.size.x
	var height: Vector3 = Vector3.UP * aabb.size.y

	var p1 := aabb.position
	var p2 := p1 + width
	var p3 := p1 + length
	var p4 := p3 + width

	var p5 := p1 + height
	var p6 := p2 + height
	var p7 := p3 + height
	var p8 := p4 + height

	draw_line(p1, p2, color, color, lifetime)
	draw_line(p1, p3, color, color, lifetime)
	draw_line(p2, p4, color, color, lifetime)
	draw_line(p3, p4, color, color, lifetime)

	draw_line(p1, p5, color, color, lifetime)
	draw_line(p2, p6, color, color, lifetime)
	draw_line(p3, p7, color, color, lifetime)
	draw_line(p4, p8, color, color, lifetime)

	draw_line(p5, p6, color, color, lifetime)
	draw_line(p5, p7, color, color, lifetime)
	draw_line(p6, p8, color, color, lifetime)
	draw_line(p7, p8, color, color, lifetime)


## Draw a marker shaped like an "x" at [param position] with color
## [param color]. It stays on screen for [param lifetime] seconds. The size of
## each arm of the "x" is [param size] units.
func draw_marker(pos: Vector3, color: Color, lifetime := 0.0, size := 0.5):
	var camera := get_viewport().get_camera_3d()
	var cam_basis := camera.global_basis
	var cam_x := cam_basis.x
	var cam_y := cam_basis.y

	draw_line(
		pos + (cam_x + cam_y).normalized() * size,
		pos + (-cam_x - cam_y).normalized() * size,
		color, color, lifetime
	)
	draw_line(
		pos + (-cam_x + cam_y).normalized() * size,
		pos + (cam_x - cam_y).normalized() * size,
		color, color, lifetime
	)


## Class representing line data.
class LineInfo extends RefCounted:
	## Time the line has been displayed.
	var time_alive := 0.0
	## Time elapsed before line is destroyed.
	var lifetime := 0.0

	## Origin point.
	var p1 := Vector3.ZERO
	## Color of the origin point.
	var c1 := Color.WHITE
	## Destination point.
	var p2 := Vector3.ZERO
	## Color of the destination point.
	var c2 := Color.WHITE
