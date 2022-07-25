class_name HorizontalMotion
extends CharacterMotion
# Responsible for horizontal movement (i.e. WASD controls).

@export_range(0, 30, 1) var movement_speed := 10.0
@export_range(1, 100, 1) var movement_acceleration := 50.0

var _velocity: Vector3


func process_motion(ctx: MotionContext, delta: float):
	var character := ctx.character

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	var cam_basis := Basis.IDENTITY.rotated(Vector3.UP, character.camera.camera_rotation.y)
	var direction_flat := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var slope_transform := Basis(Quaternion(Vector3.UP, character.ground_normal))
	var direction := slope_transform * direction_flat

	var target_velocity := direction * movement_speed

	# Handle transition between different ground (normals)
	if direction: # Prevent instant stop on release
		_velocity = _velocity.length() * direction

	_velocity = _velocity \
			.move_toward(target_velocity, delta * movement_acceleration)

	# If we ran into a wall last frame, adjust velocity accordingly
	if character.walls.size() == 1:
		var normal := character.walls[0]

		# Only slide if we are trying to move into the wall
		if direction.dot(normal) < 0:
			_velocity = _velocity.slide(normal)

	# Update state
	if direction.length_squared() > 0:
		ctx.new_state |= Character.CharacterState.WALKING

	# Update rotation
	# The rigidbody should never be scaled, so scale is reset when setting basis.
	if character.camera.camera_mode == CameraController.CameraMode.FIRST_PERSON:
		character.transform.basis = cam_basis
	elif direction:
		var movement_basis := Basis(Quaternion(Vector3.FORWARD, direction_flat))

		# Orthonormalize for floating point precision errors.
		character.transform.basis = character.transform.basis.orthonormalized() \
				.slerp(movement_basis, Utils.lerp_weight(delta))

	ctx.offset += _velocity * delta
