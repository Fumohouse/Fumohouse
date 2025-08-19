class_name CharacterPhysicalMotionProcessor
extends CharacterMotionProcessor
## Handles jumping and falling.

const ID := &"physical"
## Use this message with a [float] to add drag to the motion.
##
## Shared with [CharacterHorizontalMotionProcessor].
const DRAG := &"drag"
## Use this message with [code]0[/code] to block jumping, or a greater number to
## force a jump of that height.
const JUMP_FLAG := &"jump_flag"

## Gravity, in m/s per second.
var gravity := 50.0

## Target jump height, in meters.
var jump_height := 4.5
## Amount of time after falling to allow a jump, in seconds.
var jump_forgiveness := 0.2
## The factor to multiply motion by when bouncing off of an obstacle (i.e.,
## ceiling) during a jump.
var jump_bounce_factor := 0.7

## Threshold time (seconds) before
## [constant CharacterMotionState.CharacterState.FALLING] is applied.
var falling_time := 0.3
## Minimum altitude to enter the
## [constant CharacterMotionState.CharacterState.FALLING] state..
var falling_altitude := 2.0

## Terminal falling velocity, in m/s.
var terminal_velocity := 48.0

## Velocity induced by this processor.
var _velocity := Vector3.ZERO
## Current time (seconds) airborne.
var _airborne_time := 0.0
## Whether to block jumping, reset until the character is grounded.
var _cancel_jump := false


func _init():
	id = ID


func _initialize():
	if state.node is RigidBody3D:
		var default_gravity := ProjectSettings.get_setting(&"physics/3d/default_gravity") as float
		(state.node as RigidBody3D).gravity_scale = gravity / default_gravity


func _process(delta: float, cancelled: bool):
	if cancelled:
		_velocity = Vector3.ZERO
		_airborne_time = 0.0
		return

	var was_jumping := state.is_state(CharacterMotionState.CharacterState.JUMPING)
	var jump_msg := ctx.messages.get(JUMP_FLAG)

	if ctx.is_grounded and not was_jumping or state.is_ragdoll:
		_velocity = Vector3.ZERO
		_cancel_jump = jump_msg == 0
	else:
		_velocity += Vector3.DOWN * gravity * delta
		_velocity = _velocity.limit_length(terminal_velocity)

	if DRAG in ctx.messages:
		_velocity = CommonUtils.apply_drag(_velocity, ctx.messages[DRAG], delta)

	if (
		jump_msg
		or (
			ctx.motion.jump
			and _airborne_time < jump_forgiveness
			and not _cancel_jump
			and not was_jumping
		)
	):
		_velocity = Vector3.UP * _get_jump_velocity(jump_msg if jump_msg else jump_height)
		_cancel_jump = true
		ctx.set_state(CharacterMotionState.CharacterState.JUMPING)

		state.set_ragdoll(false)
	elif was_jumping and _velocity.y >= 0.0 and not state.is_ragdoll:
		# Persist jump state until falling
		ctx.set_state(CharacterMotionState.CharacterState.JUMPING)

		# Hit detection
		var roof_params := PhysicsTestMotionParameters3D.new()
		roof_params.from = state.node.global_transform
		roof_params.motion = Vector3.UP * _velocity.y * delta
		roof_params.margin = state.margin

		var roof_result := PhysicsTestMotionResult3D.new()

		if state.test_motion(roof_params, roof_result):
			_velocity = _velocity.bounce(roof_result.get_collision_normal()) * jump_bounce_factor

	ctx.add_offset(_velocity * delta)

	# Decide whether character is falling
	if ctx.is_grounded:
		_airborne_time = 0.0
	else:
		_airborne_time += delta

		if _airborne_time > falling_time and _velocity.y < 0.0:
			if state.is_state(CharacterMotionState.CharacterState.FALLING):
				ctx.set_state(CharacterMotionState.CharacterState.FALLING)
			else:
				var fall_ray_params := PhysicsRayQueryParameters3D.new()
				fall_ray_params.from = state.node.global_position
				fall_ray_params.to = fall_ray_params.from + Vector3.DOWN * falling_altitude

				var fall_ray_result: Dictionary = (
					state.node.get_world_3d().direct_space_state.intersect_ray(fall_ray_params)
				)
				if fall_ray_result.is_empty():
					ctx.set_state(CharacterMotionState.CharacterState.FALLING)


func _get_velocity() -> Variant:
	return _velocity


func _get_jump_velocity(height: float) -> float:
	# Kinematics
	return sqrt(2 * gravity * height)
