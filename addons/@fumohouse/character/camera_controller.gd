class_name CameraController
extends Node3D
## A component that controls a [Camera3D].

## Fired when the [member mode] changes.
signal mode_changed(new_mode: CameraMode)

const CAMERA_MAX_X_ROT = PI / 2 - 1e-2

enum CameraMode {
	## The camera takes the perspective of the [member focus_node].
	MODE_FIRST_PERSON,
	## The camera focuses on the [member focus_node].
	MODE_THIRD_PERSON,
	## The camera is free to move.
	MODE_FLOATING
}

## The camera to control.
@export var camera: Camera3D

## The vertical offset of the camera's focal point from [member focus_node].
@export var camera_offset := 2.5

## The minimum distance the camera can be from [member focus_node].
@export_range(0.0, 200.0) var min_focus_distance := 0.0

## The maximum distance the camera can be from [member focus_node].
@export_range(0.0, 200.0) var max_focus_distance := 50.0

## The target distance between the camera and [member focus_node].
@export_range(0.0, 200.0) var focus_distance := 5.0

## The movement speed of the camera in [constant CameraMode.MODE_FLOATING].
@export_range(1.0, 100.0) var move_speed := 16.0

## The movement speed of the camera in [constant CameraMode.MODE_FLOATING] while
## running.
@export_range(1.0, 100.0) var move_speed_fast := 16.0

## The node to focus on.
@export var focus_node: Node3D

## The current [enum CameraMode].
var mode := CameraMode.MODE_FIRST_PERSON

var _sens_first_person := 0.0
var _sens_third_person := 0.0
var _zoom_sens := 0.0

var camera_rotation := Vector2.ZERO
var _rotating := false
var _last_mouse_pos := Vector2.ZERO
var _focus_distance := focus_distance

@onready var _cm := ConfigManager.get_singleton()


func _ready():
	# Defer to wait for ConfigManager to be ready (e.g., for the character
	# preview in main.tscn)
	_apply_fov.call_deferred()
	_apply_sens_first_person.call_deferred()
	_apply_sens_third_person.call_deferred()
	_apply_zoom_sens.call_deferred()
	_cm.value_changed.connect(_on_config_value_changed)


func _process(delta: float):
	if not camera.current:
		return

	# "Tween" focal distance
	if mode != CameraMode.MODE_FLOATING:
		if absf(focus_distance - _focus_distance) >= 1e-2:
			_focus_distance = lerpf(_focus_distance, focus_distance, CommonUtils.lerp_weight(delta))
		else:
			_focus_distance = focus_distance

	var old_mode := mode

	if not focus_node:
		mode = CameraMode.MODE_FLOATING

		var direction := Input.get_vector(
			"move_left", "move_right", "move_forward", "move_backward"
		)
		var speed := move_speed_fast if Input.is_action_pressed("move_run") else move_speed
		camera.position += speed * delta * (camera.basis * Vector3(direction.x, 0, direction.y))

		_process_first_person()
	elif focus_distance == 0.0:
		mode = CameraMode.MODE_FIRST_PERSON
		_set_camera_rotating(true)
		_process_first_person()
	else:
		if mode == CameraMode.MODE_FIRST_PERSON:
			_set_camera_rotating(false)

		mode = CameraMode.MODE_THIRD_PERSON
		_process_third_person()

	if old_mode != mode:
		mode_changed.emit(mode)


func _unhandled_input(event: InputEvent):
	if not CommonUtils.do_game_input(self):
		return

	var handle_input := false

	# Zoom
	if focus_node:
		handle_input = true

		# Hardcode a few gestures (mainly for macOS)
		if event.is_action_pressed("camera_zoom_in"):
			focus_distance = maxf(focus_distance - _zoom_sens, min_focus_distance)
		elif event.is_action_pressed("camera_zoom_out"):
			focus_distance = minf(focus_distance + _zoom_sens, max_focus_distance)
		elif event is InputEventPanGesture:
			var epg := event as InputEventPanGesture
			# Value given in pixels. Roughly convert to scroll ticks to preserve
			# only one sensitivity setting.
			var viewport_height := get_tree().root.content_scale_size.y
			if viewport_height == 0:
				viewport_height = get_tree().root.size.y

			# Estimate a scroll tick is around 2% of the screen height?
			const SCROLL_TICK_FRAC := 0.02
			var delta := _zoom_sens * epg.delta.y / (viewport_height * SCROLL_TICK_FRAC)

			focus_distance = clampf(focus_distance + delta, min_focus_distance, max_focus_distance)
		elif event is InputEventMagnifyGesture:
			var emg := event as InputEventMagnifyGesture
			focus_distance = clampf(
				focus_distance / emg.factor, min_focus_distance, max_focus_distance
			)
		else:
			handle_input = false

	# Rotate
	if event is InputEventMouseMotion and _rotating:
		var relative := (event as InputEventMouseMotion).relative
		var rot_delta := (
			relative
			* (_sens_first_person if mode == CameraMode.MODE_FIRST_PERSON else _sens_third_person)
		)

		camera_rotation = Vector2(
			clampf(camera_rotation.x - rot_delta.y, -CAMERA_MAX_X_ROT, CAMERA_MAX_X_ROT),
			fmod(camera_rotation.y - rot_delta.x, TAU)
		)

		handle_input = true

	# Trigger rotate
	if mode != CameraMode.MODE_FIRST_PERSON and event.is_action("camera_rotate"):
		_set_camera_rotating(event.is_action_pressed("camera_rotate"))
		handle_input = true

	if handle_input:
		get_viewport().set_input_as_handled()


## Get the position that the camera should focus on. Only valid if there is a
## [member focus_node].
func get_focal_point() -> Vector3:
	if focus_node:
		return focus_node.global_position + focus_node.global_basis.y * camera_offset

	return Vector3.ZERO


## Call when popup (e.g., in-game menu) opens.
func handle_popup():
	if mode == CameraMode.MODE_THIRD_PERSON or mode == CameraMode.MODE_FLOATING:
		_set_camera_rotating(false)


func _set_camera_rotating(rotating: bool):
	if _rotating == rotating:
		return

	if rotating:
		_last_mouse_pos = get_window().get_mouse_position()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_window().warp_mouse(_last_mouse_pos)

	_rotating = rotating


func _process_first_person():
	if focus_node:
		camera.global_transform = Transform3D(Basis.IDENTITY, get_focal_point())

	camera.rotation.x = camera_rotation.x
	camera.rotation.y = camera_rotation.y


func _process_third_person():
	var focal_point := get_focal_point()
	var cam_basis := Basis.IDENTITY.rotated(Vector3.RIGHT, camera_rotation.x).rotated(
		Vector3.UP, camera_rotation.y
	)

	var pos := focal_point + cam_basis * Vector3(0, 0, _focus_distance)

	var parameters := PhysicsRayQueryParameters3D.new()
	parameters.from = focal_point
	parameters.to = pos

	var result := get_world_3d().direct_space_state.intersect_ray(parameters)
	if not result.is_empty():
		# Minimize clipping into walls, etc.
		const HIT_MARGIN := 0.05
		pos = (result["position"] as Vector3) + (result["normal"] as Vector3) * HIT_MARGIN

	camera.global_transform = Transform3D(Basis.IDENTITY, pos).looking_at(focal_point, Vector3.UP)


func _on_config_value_changed(key: StringName):
	if key == &"graphics/fov":
		_apply_fov()
	elif key == &"input/sens/camera/first_person":
		_apply_sens_first_person()
	elif key == &"input/sens/camera/third_person":
		_apply_sens_third_person()
	elif key == &"input/sens/camera/zoom":
		_apply_zoom_sens()


func _apply_fov():
	camera.fov = _cm.get_opt(&"graphics/fov")


func _apply_sens_first_person():
	_sens_first_person = deg_to_rad(_cm.get_opt(&"input/sens/camera/first_person"))


func _apply_sens_third_person():
	_sens_third_person = deg_to_rad(_cm.get_opt(&"input/sens/camera/third_person"))


func _apply_zoom_sens():
	_zoom_sens = _cm.get_opt(&"input/sens/camera/zoom")
