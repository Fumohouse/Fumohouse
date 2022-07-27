class_name LadderMotion
extends CharacterMotion
# Responsible for handling ladder climbing.


@export_range(0, 50) var forward_velocity := 8.0
@export_range(0, 50) var climb_velocity := 8.0
@export_range(0, 60, 1, "degrees") var max_angle := 30.0

@export_range(0, 2) var break_height := 0.5


static func get_id() -> StringName:
	return &"ladder"


func process_motion(ctx: MotionContext, delta: float):
	var character := ctx.character

	if character.walls.size() == 0:
		return

	var collide_params := PhysicsShapeQueryParameters3D.new()
	collide_params.shape = character.capsule
	collide_params.transform = character.capsule_transform
	collide_params.collide_with_areas = true
	collide_params.collide_with_bodies = false
	collide_params.margin = character.margin

	var result := character.get_world_3d().direct_space_state.intersect_shape(collide_params)

	var ladder: Area3D
	for data in result:
		if data.collider.is_in_group("ladder"):
			ladder = data.collider
			break

	if not ladder:
		return

	var ladder_basis := ladder.global_transform.basis
	var ladder_fwd := -ladder_basis.z

	# Check if the ladder forward direction matches any walls
	var wall_found := false

	for wall in character.walls:
		const ANGLE_MARGIN := 0.1

		# Compare to a flat vector
		var compare_normal := -wall.normal
		compare_normal.y = 0
		compare_normal = compare_normal.normalized()

		if compare_normal.angle_to(ladder_fwd) < ANGLE_MARGIN:
			wall_found = true
			break

	if not wall_found:
		return false

	var char_fwd := -character.global_transform.basis.z
	if char_fwd.angle_to(ladder_fwd) > deg2rad(max_angle):
		return

	var direction_flat := ctx.cam_basis_flat * ctx.input_direction
	var movement_angle := direction_flat.angle_to(ladder_fwd)

	if direction_flat.length_squared() > 0:
		var offset := ladder_basis.y * climb_velocity * delta

		if movement_angle < deg2rad(max_angle):
			# Add a forward velocity to make the exit (at the top) much smoother
			ctx.offset += offset + ladder_fwd * forward_velocity * delta
		elif absf(PI - movement_angle) < deg2rad(max_angle):
			ctx.offset -= offset

			# Since we are going backwards, cancel horiz. motion to avoid breaking.
			# (and to avoid WALKING state)
			# Check for the ground in case we are at a safe distance to break anyway
			var ground_params := PhysicsRayQueryParameters3D.new()
			ground_params.from = character.bottom_pos
			ground_params.to = ground_params.from + Vector3.DOWN * break_height

			var ground_result := character.get_world_3d().direct_space_state.intersect_ray(ground_params)

			if not ground_result.has("normal") or not character.is_stable_ground(ground_result.normal):
				ctx.cancel(HorizontalMotion)

	ctx.cancel(PhysicalMotion)
	ctx.cancel(StairsMotion)

	# WALKING doesn't make sense here, but its processor is still run under some circumstances
	ctx.cancelled_states |= Character.CharacterState.WALKING

	ctx.new_state |= Character.CharacterState.CLIMBING
