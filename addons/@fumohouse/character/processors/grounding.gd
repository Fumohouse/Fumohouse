class_name CharacterGroundingMotionProcessor
extends CharacterMotionProcessor
## Determines whether the character is grounded, and what ground it is
## standing on.

const ID := &"grounding"

## Use this message key with a [Vector3] to override the ground normal.
const GROUND_OVERRIDE = &"ground_override"

## Distance to ground to be considered "grounded," in meters.
var grounding_distance := 0.1


func _init():
	id = ID


func _process(_delta: float, _cancelled: bool):
	if GROUND_OVERRIDE in ctx.messages:
		ctx.is_grounded = true
		ctx.ground_normal = ctx.messages[GROUND_OVERRIDE]
		return

	var params := PhysicsTestMotionParameters3D.new()
	params.from = state.node.global_transform
	params.motion = Vector3.DOWN * grounding_distance
	params.margin = state.margin
	params.max_collisions = 4

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

		var should_snap = (
			not state.is_ragdoll
			and is_zero_approx(state.ctx.offset.y)
			and not state.is_state(CharacterMotionState.CharacterState.SWIMMING)
		)
		if found_ground and should_snap:
			const MAX_UP_SNAP := 0.01

			# dot to account for any possible horiz. movement due to depenetration
			var snap_length := Vector3.DOWN.dot(result.get_travel())
			if absf(snap_length) > state.margin and snap_length > -MAX_UP_SNAP:
				ctx.add_offset(Vector3.DOWN * snap_length * (1 - state.margin))

	if not found_ground:
		ctx.is_grounded = false
		ctx.ground_normal = Vector3.ZERO
