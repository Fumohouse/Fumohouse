class_name CharacterMoveMotionProcessor
extends CharacterMotionProcessor
## Processor responsible for moving the character.

const ID := &"move"

## Use this message to cancel the adjustment that makes the character upright.
const CANCEL_UPRIGHTING := &"cancel_uprighting"
const UPRIGHTING_FACTOR := 5.0e-6

## Force (Newtons) used to push objects.
var push_force := 70.0


func _init():
	id = ID


func _process(delta: float, cancelled: bool):
	if cancelled:
		ctx.velocity = Vector3.ZERO
		return

	var orig_transform := state.node.global_transform

	var res: Dictionary = _move(ctx.offset)
	var offset := res["offset"] as Vector3
	var recovery := res["recovery"] as Vector3

	# Apply smooth recovery if _move didn't need to apply it already. For
	# recovery to work and not cause issues, terrain/in-world objects and the
	# character should be on different physics layers.
	if recovery != Vector3.ZERO:
		offset += recovery * CommonUtils.lerp_weight(delta, 1e-10)

	ctx.velocity = offset / delta

	var target_basis: Basis

	if state.is_ragdoll or ctx.messages.get(CANCEL_UPRIGHTING, false):
		target_basis = ctx.new_basis
	else:
		target_basis = ctx.new_basis.slerp(
			CommonUtils.basis_upright(ctx.new_basis),
			CommonUtils.lerp_weight(delta, UPRIGHTING_FACTOR)
		)

	state.node.global_transform = Transform3D(target_basis, orig_transform.origin + offset)


func _move(motion: Vector3) -> Dictionary:
	var orig_transform := state.node.global_transform

	var params := PhysicsTestMotionParameters3D.new()
	params.margin = state.margin

	var result := PhysicsTestMotionResult3D.new()

	var slides := 0
	var remaining := motion
	var offset := Vector3.ZERO
	var recovery := Vector3.ZERO

	const MAX_SLIDES := 5

	while ((slides < MAX_SLIDES and remaining.length_squared() > 1e-3) or
			# Add an extra slide when not ragdolling for recovery
			(not state.is_ragdoll and slides == 0)):
		params.from = orig_transform.translated(offset)
		params.motion = remaining

		var did_collide := state.test_motion(params, result)
		if not did_collide:
			offset += remaining

			# In case we are passing inside a body without detection
			if not ctx.body_intersections.is_empty():
				recovery = _custom_recovery(offset)

			break

		var normal := result.get_collision_normal()
		var rid := result.get_collider_rid()

		# Physics system pain
		var travel := result.get_travel()
		var motion_normal := remaining.normalized()
		var projected_motion := motion_normal * travel.dot(motion_normal)

		var actual_motion := projected_motion
		var builtin_recovery := travel - projected_motion

		# Limit possible builtin recovery. Custom routine is run at the end.
		const MAX_BUILTIN_RECOVERY := 0.05
		if builtin_recovery.length_squared() <= MAX_BUILTIN_RECOVERY * MAX_BUILTIN_RECOVERY:
			actual_motion += builtin_recovery

		if (not state.is_ragdoll and
				not (ctx.is_grounded and rid == ctx.ground_rid) and
				state.should_push(rid)):
			var body_state := PhysicsServer3D.body_get_direct_state(rid)
			body_state.apply_force(
				motion_normal * push_force,
				result.get_collision_point() - body_state.transform.origin
			)

		offset += actual_motion
		remaining -= actual_motion

		# Sometimes normal is in the same direction as the motion (e.g. moving
		# in the same direction as a platform touching the character). Don't
		# bother sliding then, otherwise motion will be almost completely
		# eliminated for no reason.
		var normal_ang := normal.dot(motion_normal)
		if normal_ang < 0 and not is_zero_approx(normal_ang):
			remaining = remaining.slide(normal)

		slides += 1

	#if slides == MAX_SLIDES:
	#	offset += _custom_recovery(offset)
	# Jolt allows movement inside of a collider. Disregard slides == MAX_SLIDES
	# and always run recovery.
	recovery += _custom_recovery(offset)

	return {
		"offset": offset,
		"recovery": recovery,
	}


func _custom_recovery(offset: Vector3) -> Vector3:
	# Based on Godot's builtin recovery (servers/physics_3d/godot_space_3d.cpp).
	# The aim is to 1) make recovery primarily vertical unless absolutely
	# necessary, and 2) to work around a Godot issue where contact pairs for the
	# cylinder part of capsules in some colliders cause recovery to fail.

	if state.is_ragdoll:
		return Vector3.ZERO

	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = state.main_collision_shape
	params.collision_mask = state.node.collision_mask
	params.transform = state.main_collider.global_transform.translated(offset)
	params.exclude = [state.rid]

	var MAX_PAIRS := 16
	var result: Array[Vector3] = state.node.get_world_3d().direct_space_state.collide_shape(params, MAX_PAIRS)
	if result.is_empty():
		return Vector3.ZERO

	# Find capsule collider transform
	var capsule_shape := state.main_collision_shape
	var capsule_transform := state.main_collider.global_transform.translated(offset)
	var capsule_cyl_height := capsule_shape.height - 2 * capsule_shape.radius
	var capsule_cyl_base_pos := (
			capsule_transform.origin - capsule_transform.basis.y * capsule_cyl_height / 2)
	var capsule_cyl_transform := Transform3D(capsule_transform.basis, capsule_cyl_base_pos)
	var capsule_cyl_transform_inv := capsule_cyl_transform.inverse()

	var is_inside_cylinder := func (cyl_pos: Vector3) -> bool:
		if cyl_pos.y < 0 or cyl_pos.y > capsule_cyl_height:
			return false

		const MARGIN := 0.01
		var a_sq := cyl_pos.x * cyl_pos.x
		var b_sq := cyl_pos.z * cyl_pos.z
		var c_sq := (capsule_shape.radius + MARGIN) * (capsule_shape.radius + MARGIN)
		return a_sq + b_sq <= c_sq

	var recovery := Vector3.ZERO
	for i in range(0, result.size(), 2):
		var a := result[i] as Vector3
		var b := result[i + 1] as Vector3

		# Position local to cylinder
		var cyl_a := capsule_cyl_transform_inv * a
		var cyl_b := capsule_cyl_transform_inv * b

		# Recompute points if necessary
		# Mainly addresses (1) and (2) above
		var min_len := capsule_shape.radius / 2
		if (is_inside_cylinder.call(cyl_a) and is_inside_cylinder.call(cyl_b) and
				is_equal_approx(cyl_a.y, cyl_b.y) and
				# When the points are close together, the player is close to the
				# edge of the intersecting body. In that case, it's most likely
				# that the horizontal movement is correct.
				(b - a).length_squared() > min_len * min_len):
			# Recompute the pair to be vertical
			# Assume this pair lies pretty much exactly on the ground
			const RAY_MARGIN := 0.01
			var ray_params := PhysicsRayQueryParameters3D.new()
			ray_params.from = b + Vector3.UP * RAY_MARGIN
			ray_params.to = b + Vector3.DOWN * RAY_MARGIN
			ray_params.exclude = [state.rid]

			var ray_result: Dictionary = state.node.get_world_3d().direct_space_state.intersect_ray(ray_params)
			if not ray_result.is_empty():
				var hit_normal := ray_result["normal"] as Vector3
				# If zero then the ray was inside the body it hit (happens often
				# when being pushed by a wall)
				if not hit_normal.is_zero_approx():
					var hit_pos := ray_result["position"] as Vector3
					a = state.node.position + offset
					b = Vector3(a.x, hit_pos.y, a.z)

		# Compute recovery
		var direction := (b - a).normalized()
		# Subtract recovery from b to avoid double counting certain contacts
		var depth := direction.dot(b - recovery) - direction.dot(a)

		if depth > 0:
			recovery += direction * depth

	return recovery
