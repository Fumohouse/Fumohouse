class_name PhysicalMotion
extends CharacterMotion
# Responsible for all motion which should be affected by gravity
# (falling, jumping, etc.)


@export_range(0, 1000) var gravity := 50.0
@export_range(0, 50) var jump_height := 4.5

@export_range(0, 1) var falling_time := 0.2
@export_range(0, 10) var falling_altitude := 2

var _velocity: Vector3
var _airborne_time: float


static func get_id() -> StringName:
	return &"physical"


func handle_cancel(_ctx: MotionContext):
	_velocity = Vector3.ZERO
	_airborne_time = 0


func process_motion(ctx: MotionContext, delta: float):
	var character := ctx.character

	if character.is_grounded and not character.is_state(Character.CharacterState.JUMPING):
		_velocity = Vector3.ZERO

		if Input.is_action_pressed("move_jump"):
			_velocity = Vector3.UP * _get_jump_velocity()
			ctx.new_state |= Character.CharacterState.JUMPING
	else:
		_velocity += Vector3.DOWN * gravity * delta

	# Persist jump state until touched ground
	if character.is_state(Character.CharacterState.JUMPING) and _velocity.y > 0:
		ctx.new_state |= Character.CharacterState.JUMPING

	ctx.offset += _velocity * delta

	# Decide whether the character is falling
	if character.is_grounded:
		_airborne_time = 0
	else:
		_airborne_time += delta
		if _airborne_time > falling_time and character.velocity.y < 0:
			if character.is_state(Character.CharacterState.FALLING):
				ctx.new_state |= Character.CharacterState.FALLING
			else:
				var fall_ray_params := PhysicsRayQueryParameters3D.new()
				fall_ray_params.from = character.bottom_pos
				fall_ray_params.to = fall_ray_params.from + Vector3.DOWN * falling_altitude

				var fall_ray_result = character.get_world_3d().direct_space_state.intersect_ray(fall_ray_params)
				if not fall_ray_result.has("collider"):
					ctx.new_state |= Character.CharacterState.FALLING


func _get_jump_velocity() -> float:
	# Kinematics
	return sqrt(2 * gravity * jump_height)
