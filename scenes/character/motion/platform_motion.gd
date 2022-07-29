class_name PlatformMotion
extends CharacterMotion
# Responsible for moving the character when it is standing on a moving platform.


@export_range(0, 1) var drag_coeff := 0.005

var _linear_velocity: Vector3
var _angular_velocity: float


func process_motion(ctx: MotionContext, delta: float):
	var character := ctx.character

	if character.is_grounded:
		var body_state := PhysicsServer3D.body_get_direct_state(character.ground_rid)

		_linear_velocity = body_state.get_velocity_at_local_position(
			character.global_position - body_state.transform.origin
		)

		_angular_velocity = body_state.angular_velocity.y
	else:
		# Physically imprecise but probably good enough (and better than nothing)
		_linear_velocity = _linear_velocity.move_toward(Vector3.ZERO, drag_coeff * _linear_velocity.length())
		_angular_velocity = move_toward(_angular_velocity, 0, drag_coeff * _angular_velocity)

	ctx.offset += _linear_velocity * delta
	ctx.angular_offset += _angular_velocity * delta
