class_name CharacterSeparatorMotionProcessor
extends CharacterMotionProcessor
## Handles separating characters from others in a deterministic,
## multiplayer-friendly fashion.

const ID := &"separator"

## Velocity for separation, in m/s.
var velocity := 5.0


func _init():
	id = ID


func _process(delta: float, _cancelled: bool):
	if state.is_ragdoll:
		return

	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = state.main_collision_shape
	params.collision_mask = 2  # other characters
	params.transform = state.main_collider.global_transform
	params.exclude = [state.rid]

	const MAX_PAIRS := 16
	var result: Array[Vector3] = state.node.get_world_3d().direct_space_state.collide_shape(
		params, MAX_PAIRS
	)
	if result.is_empty():
		return

	for i in range(0, result.size(), 2):
		var a := result[i]
		var b := result[i + 1]

		var direction := (b - a).normalized()

		# Handle perfect overlap
		if direction == Vector3.ZERO or direction.dot(Vector3.UP) > 0.9999:
			# Deterministic for server. Randomness would be nice but oh well
			const ANGLE := PI / 4.0
			direction = Vector3(cos(ANGLE), 0.0, sin(ANGLE))

		ctx.add_offset(velocity * delta * direction)
