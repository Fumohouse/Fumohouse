class_name CharacterPlatformMotionProcessor
extends CharacterMotionProcessor
## Handles motion induced by moving and rotating platforms.

const ID := &"platform"

## Drag coefficient to use once the character has lost contact with the
## platform.
var drag_coeff := 0.01

## Velocity induced by this processor.
var _velocity := Vector3.ZERO
## Y-axis angular velocity (rad/s) induced by this processor.
var _angular_velocity := 0


func _init():
	id = ID


func _process(delta: float, cancelled: bool):
	if cancelled or state.is_ragdoll:
		_velocity = Vector3.ZERO
		_angular_velocity = 0.0
		return

	if ctx.is_grounded:
		var ground_state := PhysicsServer3D.body_get_direct_state(ctx.ground_rid)
		_velocity = ground_state.get_velocity_at_local_position(
			state.node.global_position - ground_state.transform.origin
		)
		_angular_velocity = ground_state.angular_velocity.y
	else:
		# Physically imprecise but probably good enough (and better than nothing)
		_velocity = CommonUtils.apply_drag(_velocity, drag_coeff, delta)
		_angular_velocity = move_toward(_angular_velocity, 0, drag_coeff * _angular_velocity)

	ctx.add_offset(_velocity * delta)
	ctx.new_basis = ctx.new_basis.rotated(Vector3.UP, _angular_velocity * delta)


func _get_velocity() -> Variant:
	return _velocity
