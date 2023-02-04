class_name Character
extends RigidBody3D
# Reference: Godot physics_body_3d.cpp (MIT)
# Assumes that the origin is at the bottom of the controller.


var camera: CameraController
var _camera_path_internal: NodePath
@export_node_path("Camera3D") var camera_path: NodePath :
	get:
		return _camera_path_internal

	set(value):
		_camera_path_internal = value
		_update_camera()

@export_range(0, 1) var margin := 0.001
@export_range(0, 90, 1, "degrees") var max_ground_angle := 45.0

@export_range(0, 100) var push_force := 70.0

signal camera_updated(camera: CameraController)


enum CharacterState {
	NONE = 0,
	IDLE = 1 << 0,
	JUMPING = 1 << 1,
	FALLING = 1 << 2,
	WALKING = 1 << 3,
	CLIMBING = 1 << 4,
}


var state: CharacterState = CharacterState.IDLE

var is_grounded := false
var ground_rid: RID
var ground_normal: Vector3
var ground_override := {}


class WallInfo:
	var point: Vector3
	var normal: Vector3


# Wall normals the character ran into, updated at the end of the frame
var walls: Array[WallInfo]

var velocity := Vector3.ZERO

@onready var capsule: CapsuleShape3D = $Capsule.shape
var capsule_transform: Transform3D :
	get:
		return $Capsule.global_transform

var _motion_processors: Array[CharacterMotion] = []


func _ready():
	set_mode(PhysicsServer3D.BODY_MODE_KINEMATIC)
	_update_camera()

	for child in get_children():
		if child is CharacterMotion:
			_motion_processors.append(child)


func is_stable_ground(normal: Vector3) -> bool:
	const ANGLE_MARGIN := 0.01
	return normal.angle_to(Vector3.UP) <= deg_to_rad(max_ground_angle) + ANGLE_MARGIN


func _check_grounding(snap: bool):
	const GROUNDING_DISTANCE = 0.01

	for key in ground_override.keys():
		var normal: Vector3 = ground_override[key]
		if normal:
			is_grounded = true
			ground_normal = normal
			return

	var params := PhysicsTestMotionParameters3D.new()
	params.from = global_transform
	params.motion = Vector3.DOWN * GROUNDING_DISTANCE
	params.recovery_as_collision = true
	params.margin = margin
	params.max_collisions = 4

	var result := PhysicsTestMotionResult3D.new()
	var did_collide := test_motion(params, result)

	var found_ground := false

	if did_collide:
		for i in range(result.get_collision_count() - 1, -1, -1):
			var normal := result.get_collision_normal(i)

			if is_stable_ground(normal):
				found_ground = true
				is_grounded = true
				ground_rid = result.get_collider_rid(i)
				ground_normal = normal

		if is_grounded and snap:
			# dot to account for any possible horiz. movement due to depenetration
			var offset := Vector3.UP.dot(result.get_travel()) * Vector3.UP
			if offset.length() > margin:
				global_position += \
						offset.normalized() * (offset.length() - margin)

	if not found_ground:
		is_grounded = false
		ground_normal = Vector3.ZERO


static func _should_push(rid: RID):
	var mode := PhysicsServer3D.body_get_mode(rid)
	return mode == PhysicsServer3D.BODY_MODE_RIGID or mode == PhysicsServer3D.BODY_MODE_RIGID_LINEAR


func _update_walls():
	walls.clear()

	const WALL_MARGIN := 0.1

	var wall_params := PhysicsTestMotionParameters3D.new()
	wall_params.from = global_transform
	wall_params.motion = Vector3.ZERO
	wall_params.margin = WALL_MARGIN
	wall_params.recovery_as_collision = true
	wall_params.max_collisions = 4

	var wall_result := PhysicsTestMotionResult3D.new()
	test_motion(wall_params, wall_result)

	for i in wall_result.get_collision_count():
		var normal := wall_result.get_collision_normal(i)
		if not is_stable_ground(normal) and not _should_push(wall_result.get_collider_rid(i)):
			var wall_info := WallInfo.new()
			wall_info.point = wall_result.get_collision_point(i)
			wall_info.normal = wall_result.get_collision_normal(i)

			walls.append(wall_info)


func _move(delta: float, offset: Vector3):
	const MAX_SLIDES := 5

	var orig_pos := global_position
	var slides := 0

	var remaining := offset

	while slides < MAX_SLIDES and remaining.length_squared() > 1e-3:
		var result := move_and_collide(remaining, false, margin)

		if result:
			var normal := result.get_normal()

			var rid := result.get_collider_rid()

			if _should_push(rid):
				# TODO: If moving faster than a certain velocity (i.e. related to movement velocity),
				# apply traditional collision resolution (impulse, etc.)
				# https://www.euclideanspace.com/physics/dynamics/collision/threed/index.htm

				var body_state := PhysicsServer3D.body_get_direct_state(rid)

				body_state.apply_force(
					remaining.normalized() * push_force,
					result.get_position() - body_state.transform.origin
				)

			remaining = result.get_remainder().slide(normal)
		else:
			break

		slides += 1

	velocity = (global_position - orig_pos) / delta


func _physics_process(delta: float):
	if not camera:
		return

	var ctx := MotionContext.new()
	ctx.was_grounded = is_grounded
	ctx.character = self

	var input_direction2 := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	ctx.input_direction = Vector3(input_direction2.x, 0, input_direction2.y)
	ctx.cam_basis_flat = Basis.IDENTITY.rotated(Vector3.UP, camera.camera_rotation.y)

	_check_grounding(not is_state(CharacterState.JUMPING))

	for processor in _motion_processors:
		if processor.enabled:
			if ctx.cancelled_processors.has(processor.get_id()):
				processor.handle_cancel(ctx)
			else:
				processor.process_motion(ctx, delta)

	_move(delta, ctx.offset)
	rotate_y(ctx.angular_offset)

	_update_walls()

	if ctx.new_state == CharacterState.NONE:
		state = CharacterState.IDLE
	else:
		state = ctx.new_state & ~ctx.cancelled_states as CharacterState


func _update_camera():
	if not is_inside_tree():
		return

	if camera:
		camera.focus_node = null

	if _camera_path_internal.is_empty():
		camera = null
	else:
		camera = get_node(_camera_path_internal) as CameraController
		camera.focus_node = self
		camera_updated.emit(camera)


func test_motion(params: PhysicsTestMotionParameters3D, result: PhysicsTestMotionResult3D = null) -> bool:
	return PhysicsServer3D.body_test_motion(get_rid(), params, result)


func set_mode(mode: PhysicsServer3D.BodyMode):
	PhysicsServer3D.body_set_mode(get_rid(), mode)


func is_state(check_state: CharacterState) -> bool:
	return state & check_state == check_state
