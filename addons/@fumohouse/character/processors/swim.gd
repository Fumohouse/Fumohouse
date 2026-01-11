class_name CharacterSwimMotionProcessor
extends CharacterMotionProcessor
## Handles swimming in areas labeled as water.

const ID := &"swim"

## Amount of drag to apply to [CharacterHorizontalMotionProcessor] and
## [CharacterPhysicalMotionProcessor].
var drag_coeff := 8.0

## The minimum approximate distance (meters) of the player's collider above the
## water to allow jumping out of the water.
var min_jump_dist_above := 0.2
## The height (meters) of the jump applied when exiting the water.
var jump_out_height := 7.25


func _init():
	id = ID


func _process(delta: float, cancelled: bool):
	if cancelled or state.is_ragdoll:
		return

	var result := _is_in_water()
	if not result["in_water"]:
		return

	var submerged: bool = result["submerged"]
	var dist_above: float = result["dist_above"]

	if (
		ctx.motion.jump
		and dist_above > min_jump_dist_above
		and state.is_state(CharacterMotionState.CharacterState.SWIMMING)
	):
		# Jump with the intent of exiting the water
		ctx.messages[CharacterPhysicalMotionProcessor.JUMP_FLAG] = jump_out_height
		return

	# Handle ladders in a somewhat passable way
	if state.is_state(CharacterMotionState.CharacterState.CLIMBING):
		ctx.messages[CharacterMoveMotionProcessor.CANCEL_UPRIGHTING] = true
		ctx.messages[CharacterHorizontalMotionProcessor.CANCEL_ORIENT] = true
		ctx.new_basis = ctx.new_basis.slerp(
			CommonUtils.basis_upright(ctx.new_basis), CommonUtils.lerp_weight(delta, 1e-1)
		)

		const CHECK_DIST := 2.0
		var snap_params := PhysicsTestMotionParameters3D.new()
		snap_params.from = Transform3D(ctx.new_basis, state.node.global_position)
		snap_params.motion = ctx.cam_basis_flat * ctx.input_direction * CHECK_DIST
		snap_params.margin = state.margin

		var snap_result := PhysicsTestMotionResult3D.new()
		if state.test_motion(snap_params, snap_result):
			ctx.add_offset(snap_result.get_travel())

		return

	ctx.messages[CharacterPhysicalMotionProcessor.DRAG] = drag_coeff

	var target_basis: Variant = null
	if not ctx.input_direction.is_zero_approx():
		# Can swim if underwater or previously swimming and still in water
		var can_swim := (
			submerged
			or (
				state.is_state(CharacterMotionState.CharacterState.SWIMMING)
				and not state.is_state(CharacterMotionState.CharacterState.IDLE)
			)
		)
		if can_swim:
			ctx.set_state(CharacterMotionState.CharacterState.SWIMMING)
			ctx.cancel_state(CharacterMotionState.CharacterState.WALKING)
			ctx.cancel_processor(CharacterPhysicalMotionProcessor.ID)

			var movement_basis := Basis(
				Quaternion(Vector3.FORWARD, ctx.cam_basis_flat * ctx.input_direction).normalized()
			)

			if ctx.input_direction.dot(Vector3.FORWARD) > 0.9:
				# Essentially only going forward
				# Prevent player from swimming too high
				const MAX_DIST_ABOVE := 0.8
				var camera_angle_x := ctx.motion.camera_rotation.x  # negative when looking down
				if camera_angle_x > 0 and dist_above >= 0 and not ctx.is_grounded:
					camera_angle_x *= clampf(1 - dist_above / MAX_DIST_ABOVE, 0, 1)

				target_basis = movement_basis * Basis(Vector3.RIGHT, -PI / 2.0 + camera_angle_x)
				# ???
				ctx.messages[CharacterHorizontalMotionProcessor.MOVEMENT_DIRECTION] = (
					movement_basis * Basis(Vector3.RIGHT, camera_angle_x) * Vector3.FORWARD
				)
			else:
				# Any other direction
				target_basis = movement_basis * Basis(Vector3.RIGHT, -PI / 2.0)

			# Do a separate ray-based ground check which is more lenient and accounts for collider
			# shape causing undesired normal output
			var check_dist := state.collision_shape.size.y
			var ground_ray_params := PhysicsRayQueryParameters3D.new()
			ground_ray_params.from = state.collider.global_position + Vector3.UP * check_dist / 2.0
			ground_ray_params.to = ground_ray_params.from + Vector3.DOWN * check_dist
			ground_ray_params.exclude = [state.rid]

			var ground_result := state.node.get_world_3d().direct_space_state.intersect_ray(
				ground_ray_params
			)
			if not ground_result.is_empty():
				var actual_normal := ground_result["normal"] as Vector3
				var ground_transform := Basis(Quaternion(Vector3.UP, actual_normal).normalized())
				target_basis = ground_transform * (target_basis as Basis)

				# Add naive downward velocity to minimize intermittent detection
				var travel := (ground_ray_params.from - ground_result["position"] as Vector3).y
				const MIN_SINK_TRAVEL := 0.5
				const SINK_VELOCITY := 0.25
				if travel > MIN_SINK_TRAVEL:
					ctx.add_offset(Vector3.DOWN * SINK_VELOCITY * delta)
	elif submerged:
		ctx.set_state(
			CharacterMotionState.CharacterState.SWIMMING | CharacterMotionState.CharacterState.IDLE
		)

	# If not trying to change direction, allow orienting with WASD but not fast
	# uprighting
	ctx.messages[CharacterMoveMotionProcessor.CANCEL_UPRIGHTING] = true
	if target_basis != null:
		ctx.messages[CharacterHorizontalMotionProcessor.CANCEL_ORIENT] = true

	# Do uprighting but slower
	ctx.new_basis = ctx.new_basis.slerp(
		target_basis as Basis if target_basis != null else CommonUtils.basis_upright(ctx.new_basis),
		CommonUtils.lerp_weight(delta, 1e-2)
	)


## Determines whether the character is in water, and if so, whether they are
## submerged and how far their head is above the water.
func _is_in_water() -> Dictionary:
	var water_collider: Area3D = null
	for area in ctx.area_intersections:
		if area.is_in_group(&"water"):
			water_collider = area
			break
	if water_collider == null:
		return {"in_water": false}

	# Check depth with ray
	const MARGIN := 0.5
	var height := state.collision_shape.size.y

	var ray_params := PhysicsRayQueryParameters3D.new()
	ray_params.from = state.collider.global_position + Vector3.UP * height / 2.0
	ray_params.to = ray_params.from + Vector3.DOWN * (height + MARGIN)
	ray_params.collide_with_bodies = false
	ray_params.collide_with_areas = true

	var ray_result := state.node.get_world_3d().direct_space_state.intersect_ray(ray_params)
	if not ray_result.is_empty() and ray_result["collider"] == water_collider:
		var dist_above := (ray_params.from - ray_result["position"] as Vector3).y
		return {"in_water": true, "submerged": false, "dist_above": dist_above}

	return {"in_water": true, "submerged": true, "dist_above": -1.0}
