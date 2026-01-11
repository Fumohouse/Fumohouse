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
	var offset: Vector3 = _move(ctx.offset)

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


func _move(motion: Vector3) -> Vector3:
	var orig_transform := state.node.global_transform

	var params := PhysicsTestMotionParameters3D.new()
	params.margin = state.margin

	var result := PhysicsTestMotionResult3D.new()

	var slides := 0
	var remaining := motion
	var offset := Vector3.ZERO

	const MAX_SLIDES := 5

	while (
		(slides < MAX_SLIDES and remaining.length_squared() > 1e-3)
		# Add an extra slide when not ragdolling for recovery
		or (not state.is_ragdoll and slides == 0)
	):
		params.from = orig_transform.translated(offset)
		params.motion = remaining

		var did_collide := state.test_motion(params, result)
		if not did_collide:
			offset += remaining
			break

		var normal := result.get_collision_normal()
		var rid := result.get_collider_rid()

		# Physics system pain
		var motion_normal := remaining.normalized()

		if (
			not state.is_ragdoll
			and not (ctx.is_grounded and rid == ctx.ground_rid)
			and state.should_push(rid)
		):
			var body_state := PhysicsServer3D.body_get_direct_state(rid)
			body_state.apply_force(
				motion_normal * push_force,
				result.get_collision_point() - body_state.transform.origin
			)

		offset += result.get_travel()
		remaining -= result.get_travel()

		# Sometimes normal is in the same direction as the motion (e.g. moving
		# in the same direction as a platform touching the character). Don't
		# bother sliding then, otherwise motion will be almost completely
		# eliminated for no reason.
		var normal_ang := normal.dot(motion_normal)
		if normal_ang < 0 and not is_zero_approx(normal_ang):
			remaining = remaining.slide(normal)

		slides += 1

	return offset
