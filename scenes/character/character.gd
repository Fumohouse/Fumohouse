class_name Character
extends RigidDynamicBody3D
# Reference: Godot physics_body_3d.cpp (MIT)


@export_range(0, 1) var margin := 0.001

@export_range(0, 1000) var gravity := 50.0
@export_range(0, 50) var jump_height := 4.5

@export_range(0, 1) var falling_time := 0.2
@export_range(0, 10) var falling_altitude := 2

@export_range(0, 5) var step_height := 0.8

var _camera: CameraController
var _camera_path_internal: NodePath
@export_node_path(Camera3D) var camera_path: NodePath :
	get:
		return _camera_path_internal

	set(value):
		_camera_path_internal = value
		_update_camera()

@export_range(0, 90, 1, "degrees") var max_ground_angle := 45.0
@export_range(0, 30, 1) var movement_speed := 10.0
@export_range(1, 100, 1) var movement_acceleration := 50.0

enum CharacterState {
	NONE = 0,
	IDLE = 1 << 0,
	JUMPING = 1 << 1,
	FALLING = 1 << 2,
	WALKING = 1 << 3,
}

var state: CharacterState = CharacterState.IDLE

@onready var _bottom_pos: Position3D = $Bottom

var _is_grounded := false
var _airborne_time := 0.0
var _ground_normal: Vector3

# Wall normals the character ran into, updated at the end of the frame
var _walls: Array[Vector3]

var _vertical_velocity := Vector3.ZERO
var _movement_velocity := Vector3.ZERO

var _velocity := Vector3.ZERO


class MotionContext:
	var new_state: int = CharacterState.NONE
	var was_grounded: bool


func _ready():
	set_mode(PhysicsServer3D.BODY_MODE_KINEMATIC)
	_update_camera()


func set_mode(mode: PhysicsServer3D.BodyMode):
	PhysicsServer3D.body_set_mode(get_rid(), mode)


func _is_stable_ground(normal: Vector3) -> bool:
	const ANGLE_MARGIN := 0.01
	return normal.angle_to(Vector3.UP) <= deg2rad(max_ground_angle) + ANGLE_MARGIN


func _check_grounding(delta: float, snap: bool, ctx: MotionContext):
	const GROUNDING_DISTANCE = 0.01

	var bp := PhysicsTestMotionParameters3D.new()
	bp.from = global_transform
	bp.motion = Vector3.DOWN * GROUNDING_DISTANCE
	bp.recovery_as_collision = true
	bp.margin = margin
	bp.max_collisions = 4

	var result := PhysicsTestMotionResult3D.new()
	var did_collide := PhysicsServer3D.body_test_motion(get_rid(), bp, result)

	var found_ground := false

	if did_collide:
		for i in range(result.get_collision_count() - 1, -1, -1):
			var normal := result.get_collision_normal(i)

			if _is_stable_ground(normal):
				found_ground = true
				_is_grounded = true
				_ground_normal = normal

		if _is_grounded and snap:
			# dot to account for any possible horiz. movement due to depenetration
			var offset := Vector3.UP.dot(result.get_travel()) * Vector3.UP
			if offset.length() > margin:
				global_position += \
						offset.normalized() * (offset.length() - margin)

	if found_ground:
		_airborne_time = 0
	else:
		_airborne_time += delta
		if _airborne_time > falling_time and _velocity.y < 0:
			if is_state(CharacterState.FALLING):
				ctx.new_state |= CharacterState.FALLING
			else:
				var fall_ray_params := PhysicsRayQueryParameters3D.new()
				fall_ray_params.from = _bottom_pos.global_position
				fall_ray_params.to = fall_ray_params.from + Vector3.DOWN * falling_altitude

				var fall_ray_result = get_world_3d().direct_space_state.intersect_ray(fall_ray_params)
				if not fall_ray_result.has("collider"):
					ctx.new_state |= CharacterState.FALLING

		_is_grounded = false
		_ground_normal = Vector3.ZERO


func _move(delta: float, offset: Vector3):
	const MAX_SLIDES := 5
	var orig_pos := global_position
	var slides := 0

	var remaining := offset

	_walls = []

	while slides < MAX_SLIDES and remaining.length_squared() > 1e-3:
		var result := move_and_collide(remaining, false, margin)

		if result:
			var normal := result.get_normal()
			remaining = result.get_remainder().slide(normal)

			if not _is_stable_ground(normal) and not _walls.has(normal):
				_walls.append(normal)
		else:
			break

		slides += 1

	_velocity = (global_position - orig_pos) / delta


func _process_vertical(delta: float, ctx: MotionContext) -> Vector3:
	if _is_grounded and not is_state(CharacterState.JUMPING):
		_vertical_velocity = Vector3.ZERO

		if Input.is_action_pressed("move_jump"):
			_vertical_velocity = Vector3.UP * _get_jump_velocity()
			ctx.new_state |= CharacterState.JUMPING
	else:
		_vertical_velocity += Vector3.DOWN * gravity * delta

	# Persist jump state until touched ground
	if is_state(CharacterState.JUMPING) and _vertical_velocity.y > 0:
		ctx.new_state |= CharacterState.JUMPING

	return _vertical_velocity * delta


func _process_movement(delta: float, ctx: MotionContext) -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	var cam_basis := Basis.IDENTITY.rotated(Vector3.UP, _camera.camera_rotation.y)
	var direction_flat := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var slope_transform := Basis(Quaternion(Vector3.UP, _ground_normal))
	var direction := slope_transform * direction_flat

	var target_velocity := direction * movement_speed

	# Handle transition between different ground (normals)
	if direction: # Prevent instant stop on release
		_movement_velocity = _movement_velocity.length() * direction

	_movement_velocity = _movement_velocity.move_toward(target_velocity, delta * movement_acceleration)

	# If we ran into a wall last frame, adjust velocity accordingly
	if _walls.size() == 1:
		_movement_velocity = _movement_velocity.slide(_walls[0])

	# Update state
	if direction.length_squared() > 0:
		ctx.new_state |= CharacterState.WALKING

	# Update rotation
	if _camera.camera_mode == CameraController.CameraMode.FIRST_PERSON:
		transform.basis = cam_basis.scaled(transform.basis.get_scale())
	elif direction:
		var movement_basis := Basis(Quaternion(Vector3.FORWARD, direction_flat))

		# Orthonormalize for floating point precision errors.
		# The rigidbody should never be scaled anyway.
		transform.basis = transform.basis.orthonormalized() \
				.slerp(movement_basis, Utils.lerp_weight(delta))

	return _movement_velocity * delta


func _physics_process(delta: float):
	if not _camera:
		return

	var ctx := MotionContext.new()
	ctx.was_grounded = _is_grounded

	_check_grounding(delta, not is_state(CharacterState.JUMPING), ctx)

	var target_offset := Vector3.ZERO
	target_offset += _process_movement(delta, ctx)
	target_offset += _process_vertical(delta, ctx)

	_move(delta, target_offset)

	if ctx.new_state == CharacterState.NONE:
		state = CharacterState.IDLE
	else:
		state = ctx.new_state as CharacterState


func _update_camera():
	if not is_inside_tree():
		return

	if _camera:
		_camera.focus_node = null

	if _camera_path_internal.is_empty():
		_camera = null
	else:
		_camera = get_node(_camera_path_internal) as CameraController
		_camera.focus_node = self


func is_state(check_state: CharacterState) -> bool:
	return state & check_state == check_state


func _get_jump_velocity() -> float:
	# Kinematics
	return sqrt(2 * gravity * jump_height)
