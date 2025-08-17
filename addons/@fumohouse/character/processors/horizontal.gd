class_name CharacterHorizontalMotionProcessor
extends CharacterMotionProcessor
## Handles WASD movement and character rotation.

const ID := &"horizontal"
## Use this message to cancel the default character orientation behavior.
const CANCEL_ORIENT := &"cancel_orient"
## Use this message with a [Vector3] to override the current movement direction.
const MOVEMENT_DIRECTION := &"movement_direction"
## Use this message with a [float] to add drag to the motion.
##
## Shared with [CharacterPhysicalMotionProcessor].
const DRAG := &"drag"

## Full walking speed, in m/s.
var walk_speed := 8.0
## Full running speed, in m/s.
var run_speed := 12.0
## Acceleration (rate of change of speed), in m/s per second.
var movement_acceleration := 50.0

## Velocity induced by this processor.
var velocity := Vector3.ZERO


func _init():
	id = ID


func _process(delta: float, cancelled: bool):
	if cancelled or state.is_ragdoll:
		velocity = Vector3.ZERO
		return

	var direction_flat: Vector3 = ctx.cam_basis_flat * ctx.input_direction
	var direction: Vector3

	if MOVEMENT_DIRECTION in ctx.messages:
		direction = ctx.messages[MOVEMENT_DIRECTION]
	elif ctx.is_grounded:
		# Default to slope direction
		var slope_transform := Basis(Quaternion(Vector3.UP, ctx.ground_normal).normalized())
		direction = slope_transform * direction_flat
	else:
		direction = direction_flat

	var target_speed := run_speed if ctx.motion.run else walk_speed
	var target_velocity := direction * target_speed

	if not direction.is_zero_approx():
		# Handle transition between different ground (normals)
		velocity = velocity.length() * direction
		# Update state
		ctx.set_state(CharacterMotionState.CharacterState.WALKING)

	velocity = velocity.move_toward(target_velocity, delta * movement_acceleration)

	if DRAG in ctx.messages:
		velocity = CommonUtils.apply_drag(velocity, ctx.messages[DRAG], delta)

	if not ctx.messages.get(CANCEL_ORIENT, false):
		# Update rotation
		# The rigidbody should never be scaled, so scale is reset when setting
		# basis.
		if ctx.motion.camera_mode == CameraController.CameraMode.MODE_FIRST_PERSON:
			ctx.new_basis = ctx.cam_basis_flat
		elif not direction.is_zero_approx():
			var movement_basis := Basis(Quaternion(Vector3.FORWARD, direction_flat))
			ctx.new_basis = ctx.new_basis.slerp(
					movement_basis,
					CommonUtils.lerp_weight(delta, CharacterMoveMotionProcessor.UPRIGHTING_FACTOR))
			# Uprighting is implied in the above code. Avoid double uprighting,
			# which would be too quick.
			ctx.messages[CharacterMoveMotionProcessor.CANCEL_UPRIGHTING] = true

	ctx.add_offset(velocity * delta)


func _get_velocity() -> Variant:
	return velocity
