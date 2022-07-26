class_name Character
extends RigidDynamicBody3D
# Reference: Godot physics_body_3d.cpp (MIT)


var camera: CameraController
var _camera_path_internal: NodePath
@export_node_path(Camera3D) var camera_path: NodePath :
	get:
		return _camera_path_internal

	set(value):
		_camera_path_internal = value
		_update_camera()

@export_range(0, 1) var margin := 0.001
@export_range(0, 90, 1, "degrees") var max_ground_angle := 45.0


enum CharacterState {
	NONE = 0,
	IDLE = 1 << 0,
	JUMPING = 1 << 1,
	FALLING = 1 << 2,
	WALKING = 1 << 3,
}


var state: CharacterState = CharacterState.IDLE

var is_grounded := false
var ground_normal: Vector3
var ground_override := {}


class WallInfo:
	var point: Vector3
	var normal: Vector3


# Wall normals the character ran into, updated at the end of the frame
var walls: Array[WallInfo]

var velocity := Vector3.ZERO

@onready var _bottom_pos: Position3D = $Bottom
var bottom_pos: Vector3 :
	get:
		return _bottom_pos.global_position

@onready var capsule: CapsuleShape3D = $Capsule.shape

var _motion_processors: Array[CharacterMotion] = []


func _ready():
	set_mode(PhysicsServer3D.BODY_MODE_KINEMATIC)
	_update_camera()

	for child in get_children():
		if child is CharacterMotion:
			_motion_processors.append(child)


func set_mode(mode: PhysicsServer3D.BodyMode):
	PhysicsServer3D.body_set_mode(get_rid(), mode)


func _is_stable_ground(normal: Vector3) -> bool:
	const ANGLE_MARGIN := 0.01
	return normal.angle_to(Vector3.UP) <= deg2rad(max_ground_angle) + ANGLE_MARGIN


func _check_grounding(snap: bool):
	const GROUNDING_DISTANCE = 0.01

	for key in ground_override.keys():
		var normal: Vector3 = ground_override[key]
		if normal:
			is_grounded = true
			ground_normal = normal
			return

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
				is_grounded = true
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
	PhysicsServer3D.body_test_motion(get_rid(), wall_params, wall_result)

	for i in range(wall_result.get_collision_count()):
		var normal := wall_result.get_collision_normal(i)
		if not _is_stable_ground(normal):
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

	_check_grounding(not is_state(CharacterState.JUMPING))

	for processor in _motion_processors:
		if processor.enabled:
			processor.process_motion(ctx, delta)

	_move(delta, ctx.offset)
	_update_walls()

	if ctx.new_state == CharacterState.NONE:
		state = CharacterState.IDLE
	else:
		state = ctx.new_state as CharacterState


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


func is_state(check_state: CharacterState) -> bool:
	return state & check_state == check_state
