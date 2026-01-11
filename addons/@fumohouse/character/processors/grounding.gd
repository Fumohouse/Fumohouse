class_name CharacterGroundingMotionProcessor
extends CharacterMotionProcessor
## Determines whether the character is grounded, and what ground it is
## standing on.

const ID := &"grounding"

## Distance to ground to be considered "grounded," in meters.
var grounding_distance := 0.1

## Maximum angle from upright (in degrees) to push the character's legs out of
## the ground.
var max_rise_angle := 25.0
## Velocity, in m/s, to use when pushing the character's legs out of the ground.
var rise_velocity := 10.0


func _init():
	id = ID


func _process(delta: float, _cancelled: bool):
	# Try both: Handle cases where ground is intersecting and where there are
	# moving bodies pushing the character.
	if not _do_grounding(delta, false):
		_do_grounding(delta, true)


func _do_grounding(delta: float, ignore_intersections: bool):
	var leg_height: float = (state.get_bottom_position() - state.node.global_position).dot(
		state.node.global_basis.y
	)

	var params := PhysicsTestMotionParameters3D.new()
	params.from = state.node.global_transform
	params.motion = Vector3.DOWN * (grounding_distance + leg_height)
	params.margin = state.margin
	params.max_collisions = 4

	if ignore_intersections:
		# Prevent issues when being pushed by other bodies
		var exclude: Array[RID] = []
		for body in ctx.body_intersections:
			exclude.push_back(body.get_rid())
			params.exclude_bodies = exclude

	var result := PhysicsTestMotionResult3D.new()
	var found_ground := false

	if state.test_motion(params, result):
		for i in range(result.get_collision_count() - 1, -1, -1):
			var normal := result.get_collision_normal(i)

			if state.is_stable_ground(normal):
				found_ground = true
				ctx.is_grounded = true
				ctx.ground_rid = result.get_collider_rid(i)
				ctx.ground_normal = normal

				var collider: Object = result.get_collider(i)
				if collider is CollisionObject3D and not ctx.body_intersections.has(collider):
					ctx.body_intersections.push_back(collider)

	if not found_ground:
		ctx.is_grounded = false
		ctx.ground_normal = Vector3.ZERO
		return false

	if not state.is_ragdoll:
		# dot to account for any possible horiz. movement due to depenetration
		var snap_length := Vector3.DOWN.dot(result.get_travel()) - leg_height

		var should_snap := (
			is_zero_approx(state.ctx.offset.y)
			and not state.is_state(CharacterMotionState.CharacterState.SWIMMING)
			and snap_length > state.margin
		)
		var should_rise := (
			state.node.global_basis.y.angle_to(Vector3.UP) < deg_to_rad(max_rise_angle)
			and snap_length < -state.margin
		)
		if should_snap:
			ctx.add_offset(Vector3.DOWN * snap_length)
		elif should_rise:
			ctx.add_offset(min(-snap_length, rise_velocity * delta) * Vector3.UP)

	return true
