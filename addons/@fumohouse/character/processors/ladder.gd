class_name CharacterLadderMotionProcessor
extends CharacterMotionProcessor
## Handles climbing up and down [Area3D]s in the [code]ladder[/code] group.

const ID := &"ladder"

## Velocity (m/s) to use when climbing up/down the ladder.
var climb_velocity := 8.0
## Forward velocity (m/s) to add when exiting a ladder.
var forward_velocity := 8.0

## Maximum angle (degrees) between the forward direction of the character and
## the ladder before the character cannot climb.
var max_angle := 45.0

## Height (meters) at which the character will jump off the ladder.
var break_height := 0.5

## Velocity induced by this processor.
var _velocity := Vector3.ZERO
var is_moving := false


func _init():
	id = ID


func _process(delta: float, cancelled: bool):
	_velocity = Vector3.ZERO
	is_moving = false

	# Cannot climb ladders if not in contact with any walls
	if cancelled or state.is_ragdoll or ctx.walls.is_empty():
		return

	# Ladder check
	var ladder: Area3D
	for area in ctx.area_intersections:
		if area.is_in_group(&"ladder"):
			ladder = area
			break

	if not ladder:
		return

	# Angle check
	var ladder_basis := ladder.global_basis
	var ladder_fwd := -ladder_basis.z

	var char_transform := state.node.global_transform
	var char_fwd := -char_transform.basis.z
	var char_fwd_alt := char_transform.basis.y  # e.g., swimming

	var max_angle_rad := deg_to_rad(max_angle)
	if (
		char_fwd.angle_to(ladder_fwd) > max_angle_rad
		and char_fwd_alt.angle_to(ladder_fwd) > max_angle_rad
	):
		return

	# Wall check (descendant of area, normal alignment)
	var wall_found := false

	for wall in ctx.walls:
		const ANGLE_MARGIN := 0.01
		var compare_normal := Vector3(-wall.normal.x, 0, -wall.normal.z).normalized()
		if (
			wall.collider is Node3D
			and ladder.is_ancestor_of(wall.collider as Node3D)
			and compare_normal.angle_to(ladder_fwd) < ANGLE_MARGIN
		):
			wall_found = true
			break

	if not wall_found:
		return

	var direction_flat := ctx.cam_basis_flat * ctx.input_direction
	var movement_angle := direction_flat.angle_to(ladder_fwd)

	if direction_flat != Vector3.ZERO:
		_velocity = ladder_basis.y * climb_velocity

		if movement_angle < max_angle_rad:
			# Add a forward velocity to make the exit (at the top) much smoother
			_velocity += ladder_fwd * forward_velocity
		elif absf(PI - movement_angle) < max_angle_rad:
			_velocity *= -1

			# Since we are going backwards, cancel horiz. motion to avoid
			# breaking. Check for the ground in case we are at a safe distance
			# to break anyway.
			var ground_params := PhysicsRayQueryParameters3D.new()
			ground_params.from = char_transform.origin
			ground_params.to = ground_params.from + Vector3.DOWN * break_height

			var ground_result: Dictionary = (
				state.node.get_world_3d().direct_space_state.intersect_ray(ground_params)
			)

			if (
				ground_result.is_empty()
				or not state.is_stable_ground(ground_result["normal"] as Vector3)
			):
				ctx.cancel_processor(CharacterHorizontalMotionProcessor.ID)

		is_moving = true
		ctx.add_offset(_velocity * delta)

	ctx.cancel_processor(CharacterPhysicalMotionProcessor.ID)
	ctx.cancel_processor(CharacterStairsMotionProcessor.ID)

	ctx.cancel_state(CharacterMotionState.CharacterState.WALKING)
	ctx.set_state(CharacterMotionState.CharacterState.CLIMBING)


func _get_velocity() -> Variant:
	return _velocity
