class_name StairsMotion
extends CharacterMotion
# Responsible for allowing the character to go up stairs/steps.


const OVERRIDE_KEY := &"step_slope"

@export_range(0, 10, 1, "degrees") var max_step_angle := 3
@export_range(0.1, 2) var max_step_height := 0.5
@export_range(0.1, 2) var slope_distance := 1

var _found_stair := false

var _begin_position: Vector3
var _end_position: Vector3

var _motion_vector: Vector3
var _wall_tangent: Vector3
var _slope_normal: Vector3


static func get_id() -> StringName:
	return &"stairs"


func _reset(character):
	_found_stair = false

	_begin_position = Vector3.ZERO
	_end_position = Vector3.ZERO

	_motion_vector = Vector3.ZERO
	_wall_tangent = Vector3.ZERO
	_slope_normal = Vector3.ZERO

	character.ground_override.erase(OVERRIDE_KEY)


func handle_cancel(ctx: MotionContext):
	_reset(ctx.character)


func _handle_stairs(ctx: MotionContext) -> bool:
	const MAX_STEP_MARGIN := 0.01

	var character := ctx.character

	# Cancel if we are falling or can't find the ground
	if character.is_state(Character.CharacterState.FALLING):
		return false

	var ground_check_params := PhysicsTestMotionParameters3D.new()
	ground_check_params.from = character.global_transform
	ground_check_params.motion = Vector3.DOWN * max_step_height

	var found_ground := character.test_motion(ground_check_params)

	if not found_ground:
		return false

	var capsule_radius: float = character.capsule.radius
	var forward := -character.global_transform.basis.z

	# In case we are facing a bit diagonal compared to the step wall normal
	var check_distance := (slope_distance - capsule_radius) * 2

	# Search for the stair
	var search_params := PhysicsTestMotionParameters3D.new()
	search_params.from = character.global_transform
	search_params.motion = forward * check_distance
	search_params.max_collisions = 4
	search_params.recovery_as_collision = true
	search_params.margin = character.margin

	var search_result := PhysicsTestMotionResult3D.new()
	var search_found := character.test_motion(search_params, search_result)

	if not search_found:
		_reset(character)
		return false

	var highest_idx = 0
	var highest_point: Vector3

	const MIN_STEP := 0.01

	for i in search_result.get_collision_count():
		var point := search_result.get_collision_point(i)

		if point.y > highest_point.y:
			var step_height := point.y - character.global_position.y

			if step_height > max_step_height + MAX_STEP_MARGIN or \
					step_height < MIN_STEP:
				return false

			highest_idx = i
			highest_point = point

	var wall_normal := search_result.get_collision_normal(highest_idx)
	wall_normal.y = 0
	wall_normal = wall_normal.normalized()

	# Cancel if turned away from the step
	if -wall_normal.dot(forward) < 0.5:
		return false

	# Distance to the step
	var distance: float = -wall_normal.dot(search_result.get_travel()) + capsule_radius
	if distance > slope_distance:
		return false

	# Use ray to find true position of target point
	# and to check the step's top normal
	const RAY_MARGIN := 0.01
	const RAY_DISTANCE := 0.1

	var ray_params := PhysicsRayQueryParameters3D.new()
	ray_params.from = highest_point \
			- wall_normal * RAY_MARGIN \
			+ Vector3.UP * RAY_DISTANCE

	ray_params.to = ray_params.from + Vector3.DOWN * (RAY_DISTANCE + RAY_MARGIN)

	var ray_result := character.get_world_3d().direct_space_state.intersect_ray(ray_params)

	if not ray_result.has("normal") or \
			ray_result.normal.angle_to(Vector3.UP) > deg_to_rad(max_step_angle):
		return false

	var target_point := Vector3(highest_point.x, ray_result.position.y, highest_point.z)

	if not _found_stair or not is_equal_approx(target_point.y, _end_position.y):
		_found_stair = true
		_begin_position = character.global_position
		_end_position = target_point

		var total_motion := _end_position - _begin_position # As a vector, points "AWAY"
		_motion_vector = (-wall_normal * total_motion.dot(-wall_normal) \
				+ Vector3.DOWN * total_motion.dot(Vector3.DOWN)).normalized()

		_wall_tangent = Vector3.UP.cross(wall_normal) # Points "RIGHT"
		_slope_normal = _wall_tangent.cross(_motion_vector).normalized()

		character.ground_override[OVERRIDE_KEY] = _slope_normal

	# Position on the capsule which should contact the virtual slope
	var contact_position := character.global_position \
			+ Vector3.UP * capsule_radius \
			- _slope_normal * capsule_radius

	var horiz_distance := (contact_position - _begin_position).dot(-wall_normal)
	var total_distance := (_end_position - _begin_position).dot(-wall_normal)

	var current_target := lerpf(_begin_position.y, _end_position.y, horiz_distance / total_distance)

	ctx.offset += Vector3.UP * (current_target - contact_position.y)

	return true


func process_motion(ctx: MotionContext, _delta: float):
	if not _handle_stairs(ctx):
		_reset(ctx.character)
