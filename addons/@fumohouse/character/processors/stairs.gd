class_name CharacterStairsMotionProcessor
extends CharacterMotionProcessor
## Allows character to ascend and descend stairs/steps.

const ID := &"stairs"
## Margin around [member max_step_height].
const MAX_STEP_MARGIN := 0.01

## The maximum angle between the normal of the stop of the step and vertical.
var max_step_angle := 3.0
## Minimum height to consider for steps.
var min_step_height := 0.01
## Maximum height to consider for steps.
var max_step_height := 0.5
## Distance to search to find the step to climb.
var slope_distance := 1.0

## Has a step been found?
var _found_stair := false

## Starting position of the step slope.
var _begin_position := Vector3.ZERO
## Ending position of the step slope.
var _end_position := Vector3.ZERO

## Motion from [member _begin_position] to [member _end_position], flattened in
## the direction of [member _stair_normal].
var _motion_vector := Vector3.ZERO
## Tangent vector to the step wall.
var _wall_tangent := Vector3.ZERO
## Flattened normal from side of stair, pointing in the direction of motion.
var _stair_normal := Vector3.ZERO
## Normal vector of the slope from [member _begin_position] to
## [member _end_position].
var _slope_normal := Vector3.ZERO


func _init():
	id = ID


func _process(delta: float, cancelled: bool):
	if cancelled or state.is_ragdoll:
		_reset()
		return

	if not _handle_stairs(delta):
		_reset()


## Reset the processor state.
func _reset():
	_found_stair = false

	_begin_position = Vector3.ZERO
	_end_position = Vector3.ZERO

	_motion_vector = Vector3.ZERO
	_wall_tangent = Vector3.ZERO
	_stair_normal = Vector3.ZERO
	_slope_normal = Vector3.ZERO


## Handle stair motion. Return whether a step was found.
func _handle_stairs(delta: float) -> bool:
	# Don't look for new stair unless player is moving and recently on the
	# ground
	if (not _found_stair and (ctx.input_direction.is_zero_approx() or
			state.is_state(CharacterMotionState.CharacterState.FALLING))):
		return false

	var step_up := _find_step_up()
	if step_up != null:
		_apply_motion(delta, step_up["target"] as Vector3, step_up["normal"] as Vector3)
		return true

	var step_down := _find_step_down()
	if step_down != null:
		_apply_motion(delta, step_down["target"] as Vector3, step_down["normal"] as Vector3)
		return true

	return false


## Find a step going upwards.
func _find_step_up() -> Variant:
	var char_transform := state.node.global_transform
	var forward := -char_transform.basis.z

	# 2x in case we are facing a bit diagonal compared to the step wall normal
	var check_distance := slope_distance * 2 - state.main_collision_shape.radius
	var test_result := _normal_test(char_transform, forward * check_distance)
	if test_result == null:
		return null

	var search_result := test_result["search_result"] as PhysicsTestMotionResult3D
	var wall_normal := test_result["normal"] as Vector3

	# Distance to step
	var distance := -wall_normal.dot(search_result.get_travel()) + state.main_collision_shape.radius
	if distance > slope_distance:
		return null

	var highest_point := Vector3(0.0, -1.0e20, 0.0)
	for i in search_result.get_collision_count():
		var point := search_result.get_collision_point(i)
		if point.y > highest_point.y:
			var step_height := point.y - char_transform.origin.y
			if step_height > max_step_height + MAX_STEP_MARGIN:
				return null

			highest_point = point

	# Use ray to find true position of target point and to check the step's top
	# normal
	const RAY_MARGIN := 0.01
	const RAY_DISTANCE := 0.1

	var ray_params := PhysicsRayQueryParameters3D.new()
	ray_params.from = highest_point - wall_normal * RAY_MARGIN + Vector3.UP * RAY_DISTANCE
	ray_params.to = ray_params.from + Vector3.DOWN * (RAY_DISTANCE + RAY_MARGIN)

	var ray_result: Dictionary = state.node.get_world_3d().direct_space_state.intersect_ray(ray_params)
	if ray_result.is_empty() or not _is_valid_stair(ray_result["normal"] as Vector3):
		return

	var target_point := Vector3(highest_point.x, (ray_result["position"] as Vector3).y, highest_point.z)

	# "Straighten" to wall normal
	var motion := target_point - char_transform.origin
	target_point = char_transform.origin + wall_normal * motion.dot(wall_normal) + Vector3.UP * motion.y

	return {
		"target": target_point,
		"normal": -wall_normal,
	}


## Find a step going downwards.
func _find_step_down() -> Variant:
	var char_transform := state.node.global_transform
	var forward := -char_transform.basis.z

	var dss := state.node.get_world_3d().direct_space_state

	# Fire a series of rays to determine slope end position
	var max_distance := slope_distance * 2
	var ray_motion := Vector3.DOWN * (max_step_height + MAX_STEP_MARGIN)

	const STEP_SIZE := 0.1
	const MIN_STEP_MARGIN := 0.1 # Account for grounding distance

	var target_position: Variant

	var check_ray_params := PhysicsRayQueryParameters3D.new()
	var dist := 0.0
	while dist <= max_distance:
		check_ray_params.from = char_transform.origin + forward * dist
		check_ray_params.to = check_ray_params.from + ray_motion

		var check_ray_result: Dictionary = dss.intersect_ray(check_ray_params)
		if check_ray_result.is_empty() or not _is_valid_stair(check_ray_result["normal"] as Vector3):
			break

		var pos := check_ray_result["position"] as Vector3

		if char_transform.origin.y - pos.y < min_step_height + MIN_STEP_MARGIN:
			return null

		if target_position != null and not is_equal_approx(pos.y, (target_position as Vector3).y):
			break

		target_position = pos
		dist += STEP_SIZE

	if target_position == null:
		return null

	var tp := target_position as Vector3
	# Subtract radius (to account for motion test) then add 2 * radius (to account for player on
	# edge, etc.)
	var check_distance := max_distance + state.main_collision_shape.radius
	var search_transform := Transform3D(char_transform.basis, tp + Vector3.UP * MIN_STEP_MARGIN)
	var test_result := _normal_test(search_transform, -forward * check_distance)
	if test_result == null:
		return null

	var wall_normal := test_result["normal"] as Vector3

	var motion := tp - char_transform.origin
	# Down into the step instead of away from it
	if motion.dot(wall_normal) < 0:
		return null

	# Straighten, fix size of slope to maximum size
	target_position = (char_transform.origin
			+ wall_normal * minf(motion.dot(wall_normal), slope_distance)
			+ Vector3.UP * motion.y)

	return {
		"target": target_position,
		"normal": wall_normal,
	}


func _apply_motion(delta: float, target_point: Vector3, stair_normal: Vector3):
	_found_stair = true
	_begin_position = state.node.global_position
	_end_position = target_point

	var total_motion := _end_position - _begin_position
	# total_motion as components of DOWN and stair_normal (no side-to-side)
	_motion_vector = (stair_normal * total_motion.dot(stair_normal)
			+ Vector3.DOWN * total_motion.dot(Vector3.DOWN)).normalized()

	# Points "RIGHT"
	_wall_tangent = Vector3.UP.cross(-stair_normal)
	_stair_normal = stair_normal
	_slope_normal = _wall_tangent.cross(_motion_vector).normalized()

	# Rely on [CharacterHorizontalMotionProcessor] to move up the slope
	ctx.messages[CharacterGroundingMotionProcessor.GROUND_OVERRIDE] = _slope_normal


## Test motion to find the edge of a step.
func _normal_test(from: Transform3D, motion: Vector3) -> Variant:
	var params := PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	params.margin = state.margin
	params.max_collisions = 4

	var result := PhysicsTestMotionResult3D.new()

	if not state.test_motion(params, result):
		return null

	var wall_normal := result.get_collision_normal()
	wall_normal = Vector3(wall_normal.x, 0, wall_normal.z)

	# Can happen if the normal is somehow vertical
	if wall_normal.is_zero_approx():
		return null

	return {
		"search_result": result,
		"normal": wall_normal,
	}


## Determine whether the top of the step should be considered a valid stair.
func _is_valid_stair(top_normal: Vector3) -> bool:
	return top_normal.angle_to(Vector3.UP) <= deg_to_rad(max_step_angle)
