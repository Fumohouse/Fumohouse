class_name CameraController
extends Camera3D


const CAMERA_MAX_X_ROT := PI / 2 - 1e-2;

var focus_node: Node3D

@export_range(0, 10) var camera_offset := 2.5

@export_range(0, 5) var camera_zoom_sens = 1.0
@export_range(0, 3) var camera_rotate_sens := PI / 200

@export_range(0, 200) var max_focus_distance := 50
@export_range(0, 200) var focus_distance_target := 5.0

var camera_rotation := Vector2(0, 0)
var _focus_distance = focus_distance_target

var _last_mouse_pos := Vector2.ZERO

var _camera_rotating_internal := false
var _camera_rotating := false :
	get:
		return _camera_rotating_internal
	set(value):
		if value == _camera_rotating_internal:
			return

		_camera_rotating_internal = value
		if value:
			_last_mouse_pos = get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_viewport().warp_mouse(_last_mouse_pos)


enum CameraMode {
	# Focused, no zoom
	FIRST_PERSON,

	# Focused, zoomed out
	THIRD_PERSON,

	# No focus
	FLOATING
}

var camera_mode: CameraMode


func _process_first_person():
	if focus_node:
		global_transform.origin = focus_node.global_transform.origin + Vector3(0, camera_offset, 0)
		global_transform.basis = focus_node.global_transform.basis.orthonormalized()

	rotation.x = camera_rotation.x
	rotation.y = camera_rotation.y


func _process_third_person():
	var focal_point := focus_node.global_transform.origin + Vector3(0, camera_offset, 0)
	var cam_basis := (Basis.IDENTITY
		.rotated(Vector3.RIGHT, camera_rotation.x)
		.rotated(Vector3.UP, camera_rotation.y))

	var pos = focal_point + cam_basis * Vector3(0, 0, _focus_distance)

	var parameters := PhysicsRayQueryParameters3D.new()
	parameters.from = focal_point
	parameters.to = pos

	var result := get_world_3d().direct_space_state.intersect_ray(parameters)
	if result.has("position"):
		pos = result.position - result.position.normalized() * 0.01

	global_transform = Transform3D(Basis.IDENTITY, pos).looking_at(focal_point, Vector3.UP)


func _process(delta: float):
	if not current:
		return

	# "Tween" camera focal distance
	if camera_mode != CameraMode.FLOATING:
		if abs(focus_distance_target - _focus_distance) >= 1e-2:
			_focus_distance = lerp(_focus_distance, focus_distance_target, Utils.lerp_weight(delta))
		else:
			_focus_distance = focus_distance_target

	if focus_node == null:
		camera_mode = CameraMode.FLOATING
	elif focus_distance_target == 0.0:
		camera_mode = CameraMode.FIRST_PERSON
		_camera_rotating = true
	else:
		if camera_mode == CameraMode.FIRST_PERSON:
			_camera_rotating = false

		camera_mode = CameraMode.THIRD_PERSON

	if focus_node == null or _focus_distance == 0.0:
		_process_first_person()
	else:
		_process_third_person()


func _unhandled_input(event: InputEvent):
	# Zoom
	if focus_node:
		if event.is_action_pressed("camera_zoom_in"):
			focus_distance_target = max(focus_distance_target - camera_zoom_sens, 0)
		elif event.is_action_pressed("camera_zoom_out"):
			focus_distance_target = min(focus_distance_target + camera_zoom_sens, max_focus_distance)

	# Rotate
	if event is InputEventMouseMotion and _camera_rotating:
		var rot_delta: Vector2 = event.relative * camera_rotate_sens
		if camera_mode != CameraMode.THIRD_PERSON:
			rot_delta *= 0.25

		camera_rotation.x = clamp(camera_rotation.x - rot_delta.y, -CAMERA_MAX_X_ROT, CAMERA_MAX_X_ROT)
		camera_rotation.y = fmod(camera_rotation.y - rot_delta.x, 2 * PI)

	# Trigger rotate
	if camera_mode != CameraMode.FIRST_PERSON and event.is_action("camera_rotate"):
		_camera_rotating = event.is_action_pressed("camera_rotate")
