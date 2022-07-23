class_name Billboard
extends Sprite3D


@export_range(0, 0.1) var target_pixel_size := 0.01

var _viewport: SubViewport
@onready var _camera := get_viewport().get_camera_3d()

var _orig_size: Vector2


func _ready():
	_viewport = SubViewport.new()
	_viewport.name = "Viewport"
	_viewport.disable_3d = true
	_viewport.transparent_bg = true

	add_child(_viewport)

	texture = _viewport.get_texture()
	_reparent_contents.call_deferred()


func _reparent_contents():
	# Hack: We cannot see the contents in editor otherwise.
	# https://github.com/godotengine/godot/issues/39387

	var contents: Control

	for child in get_children():
		if child is Control:
			contents = child
			break

	if not contents:
		push_error("Billboard must have a Control child in order to function.")
		return

	_orig_size = contents.size

	remove_child(contents)
	_viewport.add_child(contents)

	# Visible to false in editor to not clutter 2D view. Again a hack.
	contents.visible = true


# Gets the size of this billboarded Sprite3D in screen space.
func _get_screen_size() -> Vector2:
	var g_basis := global_transform.basis

	var world_size := _orig_size * target_pixel_size
	var world_offset := offset * target_pixel_size
	var world_origin := global_transform.origin \
			+ g_basis.x * world_offset.x \
			+ g_basis.y * world_offset.y

	var top_left := world_origin \
			- g_basis.x * world_size.x / 2 \
			+ g_basis.y * world_size.y / 2

	var bottom_right := world_origin \
			+ g_basis.x * world_size.x / 2 \
			- g_basis.y * world_size.y / 2

	var screen_tl := _camera.unproject_position(top_left)
	var screen_br := _camera.unproject_position(bottom_right)
	var screen_size = screen_br - screen_tl

	return screen_size


func _process(_delta: float):
	if not _camera:
		return

	var pos := global_transform.origin
	if _camera.is_position_behind(pos):
		visible = false
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return

	visible = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Manual billboard helps with math
	global_transform.basis = _camera.basis

	var screen_size := _get_screen_size()
	var max_size: Vector2 = get_viewport().size * 4
	var viewport_size: Vector2

	if screen_size.x > max_size.x or screen_size.y > max_size.y:
		var width = max_size.x
		var height = max_size.x * _orig_size.y / _orig_size.x
		viewport_size = Vector2(width, height)
	else:
		viewport_size = screen_size

	# I don't really know how this works.
	# This basically replicates Godot's canvas_items scaling mode.
	# Reference: window.cpp
	_viewport.size = viewport_size
	_viewport.size_2d_override = _orig_size
	_viewport.canvas_transform = Transform2D.IDENTITY.scaled(viewport_size / _orig_size)

	# Must adjust the pixel size in order to update texture size, etc.
	pixel_size = target_pixel_size * _orig_size.x / screen_size.x
