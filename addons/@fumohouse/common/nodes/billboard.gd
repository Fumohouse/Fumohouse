class_name Billboard
extends Sprite3D
## A [Sprite3D] that displays a [Control] and takes in input.

## The target size of a pixel in meters.
@export_range(0.001, 0.1, 0.01, "suffix:m") var target_pixel_size := 0.01

## Whether the billboard should follow the camera.
@export var follow_camera := true

@export_subgroup("Input")

## Whether this sprite should pass mouse inputs through to the viewport.
@export var accept_mouse_input := true

## Whether this sprite should pass keyboard inputs through to the viewport. This
## will not work without [member accept_mouse_input].
@export var accept_keyboard_input := true

## Whether this sprite is currently consuming keyboard input.
var is_focused := false

var _viewport: SubViewport
var _orig_size := Vector2.ZERO


func _ready():
	_viewport = SubViewport.new()
	_viewport.name = "Viewport"
	_viewport.disable_3d = true
	_viewport.transparent_bg = true

	add_child(_viewport)

	texture = _viewport.get_texture()
	_reparent_controls()


func _process(delta: float):
	if not visible:
		return

	var camera := get_viewport().get_camera_3d()
	if not camera:
		return

	if camera.is_position_behind(global_position):
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return

	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	if follow_camera:
		# Manual billboard helps with math
		global_transform = Transform3D(camera.global_basis, global_position)

	var screen_size: Vector2 = get_screen_size(camera)
	var max_size: Vector2 = get_window().size * 4

	var viewport_size: Vector2
	if screen_size.x > max_size.x or screen_size.y > max_size.y:
		var width := max_size.x
		var height := width * _orig_size.y / _orig_size.x
		viewport_size = Vector2(width, height)
	else:
		viewport_size = screen_size

		if not follow_camera:
			# Otherwise the size will be screwed up when viewing off-axis.
			viewport_size.y = viewport_size.x * _orig_size.y / _orig_size.x

	# I don't really know how this works.
	# This basically replicates Godot's canvas_items scaling mode.
	# Reference: window.cpp
	_viewport.size = Vector2i(viewport_size)
	_viewport.size_2d_override = Vector2i(_orig_size)
	_viewport.canvas_transform = Transform2D.IDENTITY.scaled(viewport_size / _orig_size)

	# Must adjust the pixel size in order to update texture size, etc.
	pixel_size = target_pixel_size * _orig_size.x / screen_size.x


func _unhandled_mouse(event: InputEventMouse):
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return

	var pressed := event is InputEventMouseButton and (event as InputEventMouseButton).pressed

	var plane := Plane(global_basis.z, global_position)
	var camera_ray_orig := camera.project_ray_origin(event.position)
	var camera_ray_norm := camera.project_ray_normal(event.position)

	var intersect := plane.intersects_ray(camera_ray_orig, camera_ray_norm)
	if intersect == null:
		if pressed:
			is_focused = false
		return

	var corners: Array[Vector3] = _get_corners()
	var screen_size: Vector2 = get_screen_size(camera)

	var ofs := (intersect as Vector3) - corners[0]

	var x := ofs.dot(global_basis.x)
	var y := -ofs.dot(global_basis.y)

	if x < 0 or y < 0 or x > screen_size.x or y > screen_size.y:
		if pressed:
			is_focused = false
		return

	var viewport_pos := Vector2(x, y) / pixel_size

	var viewport_evt := event.duplicate() as InputEventMouse
	viewport_evt.position = viewport_pos

	_viewport.push_input(viewport_evt, true)
	if pressed:
		is_focused = true
	get_viewport().set_input_as_handled()


func _unhandled_key(event: InputEventKey):
	if not is_focused:
		return

	_viewport.push_input(event)
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent):
	if event is InputEventMouse:
		if not accept_mouse_input:
			return
		_unhandled_mouse(event as InputEventMouse)
	elif event is InputEventKey:
		if not accept_keyboard_input:
			return
		_unhandled_key(event as InputEventKey)


## Get the target size of the billboard on the screen.
func get_screen_size(camera: Camera3D) -> Vector2:
	var corners: Array[Vector3] = _get_corners()
	var screen_tl: Vector2 = camera.unproject_position(corners[0])
	var screen_br: Vector2 = camera.unproject_position(corners[1])

	return screen_br - screen_tl


func _reparent_controls():
	# Hack: We cannot see the contents in editor otherwise.
	# https://github.com/godotengine/godot/issues/39387

	var contents: Control

	for child in get_children():
		if child is Control:
			contents = child as Control
			break

	if not contents:
		push_error("Billboard must have a Control child.")
		return

	_orig_size = contents.size
	contents.reparent(_viewport)
	# Visible is false in editor to not clutter 2D view.
	contents.show()


func _get_corners() -> Array[Vector3]:
	var world_size: Vector2 = _orig_size * target_pixel_size
	var world_offset: Vector2 = offset * target_pixel_size
	var world_origin: Vector3 = (
		global_position + global_basis.x * world_offset.x + global_basis.y * world_offset.y
	)

	var top_left: Vector3 = (
		world_origin - global_basis.x * world_size.x / 2 + global_basis.y * world_size.y / 2
	)

	var bottom_right: Vector3 = (
		world_origin + global_basis.x * world_size.x / 2 - global_basis.y * world_size.y / 2
	)

	return [top_left, bottom_right]
