class_name CharacterMotionState
extends RefCounted
## An object that tracks the state and [CharacterMotionProcessor]s for a
## character.
##
## The forward direction is -Z.
##
## The origin of the character body should be at the bottom middle of its model
## (e.g., between its feet).
##
## The character uses one box collider for the torso and separates it from the
## ground using the distance between the collider's bottom face and the
## ground. The collider should be local to scene.

## A bit field enum representing the current state of the character.
enum CharacterState {
	## Placeholder none state. Never actually set as a value of [member state].
	NONE = 0,
	## Used when no other state applies.
	IDLE = 1,
	## Character is jumping. State persists until the net velocity is down.
	JUMPING = 2,
	## Character is falling.
	FALLING = 4,
	## Character is walking.
	WALKING = 8,
	## Character is climbing (e.g., a ladder).
	CLIMBING = 16,
	## Character is sitting.
	SITTING = 32,
	## Character is swimming.
	SWIMMING = 64,
	## Character is dead and will be freed soon.
	DEAD = 32768,
}

# MANAGED EXTERNALLY #
# All of these properties must be set externally prior to [method initialize].
## The [Node] representing this character.
var node: RigidBody3D
## The [RID] of [member node].
var rid := RID()

## The character collider. Must have a [BoxShape3D] as its shape.
var collider: CollisionShape3D
## The shape of [member collider].
var collision_shape: BoxShape3D:
	get:
		return collider.shape as BoxShape3D

# OPTIONS #
## The maximum angle between the ground normal and vertical that is considered
## stable.
var max_ground_angle := 45.0  # degrees
## A generic margin value used to account for floating point errors.
var margin := 0.001

# STATE #
## [code]true[/code] if this character is in ragdoll mode.
var is_ragdoll := false
## [code]true[/code] if this character is currently queued to have the
## [constant CharacterState.DEAD] state on the next [method update].
var queue_dead := false

## The current [enum CharacterState] bitfield.
var state: int = CharacterState.IDLE
## The [Context] used for all [CharacterMotionProcessor]s.
var ctx := Context.new()

var _motion_processors: Array[CharacterMotionProcessor] = []


## Initialize this state. Prior to calling this function, set all externally
## managed configuration variables such as [member node] and [member rid].
func initialize():
	set_ragdoll(false)

	add_processor(CharacterIntersectionsMotionProcessor.new())
	add_processor(CharacterGroundingMotionProcessor.new())

	add_processor(CharacterRagdollMotionProcessor.new())
	add_processor(CharacterLadderMotionProcessor.new())
	add_processor(CharacterSwimMotionProcessor.new())

	add_processor(CharacterHorizontalMotionProcessor.new())
	add_processor(CharacterPhysicalMotionProcessor.new())
	add_processor(CharacterPlatformMotionProcessor.new())
	add_processor(CharacterCollisionMotionProcessor.new())

	add_processor(CharacterMoveMotionProcessor.new())


## Add [param processor] to this motion state.
func add_processor(processor: CharacterMotionProcessor):
	_motion_processors.append(processor)
	processor.state = self
	processor._initialize()


## Update this character's motion.
func update(motion: Motion, delta: float):
	var orig_transform := node.global_transform

	# Reset and initialize context
	ctx.reset()
	ctx.motion = motion
	ctx.input_direction = Vector3(motion.direction.x, 0, motion.direction.y)
	ctx.cam_basis_flat = Basis.IDENTITY.rotated(Vector3.UP, motion.camera_rotation.y)

	ctx.new_basis = orig_transform.basis

	# Persist death
	if queue_dead or is_state(CharacterState.DEAD):
		ctx.set_state(CharacterState.DEAD)
		queue_dead = false

	# Process
	for processor in _motion_processors:
		processor._process(delta, ctx.cancelled_processors.get(processor.ID, false))

	# Update state
	state = ctx.get_final_state()


## Get whether the character push the object with the given [param rid].
func should_push(rid: RID) -> bool:
	var mode := PhysicsServer3D.body_get_mode(rid)
	return mode == PhysicsServer3D.BODY_MODE_RIGID or mode == PhysicsServer3D.BODY_MODE_RIGID_LINEAR


## Get the bottom-middle position of this character's collider.
func get_bottom_position() -> Vector3:
	var collider_transform := collider.global_transform
	# basis.y incorporates the scale of the collider
	return collider_transform.origin - 0.5 * collision_shape.size.y * collider_transform.basis.y


## Get whether the ground with the given [param normal] is considered stable. A
## character on unstable ground falls.
func is_stable_ground(normal: Vector3):
	const ANGLE_MARGIN := 0.01
	return normal.angle_to(Vector3.UP) <= deg_to_rad(max_ground_angle) + ANGLE_MARGIN


## Use [method PhysicsServer3D.body_test_motion] to test motion.
func test_motion(params: PhysicsTestMotionParameters3D, result: PhysicsTestMotionResult3D) -> bool:
	return PhysicsServer3D.body_test_motion(rid, params, result)


## Set the [enum PhysicsServer3D.BodyMode] of this character.
func set_body_mode(mode: PhysicsServer3D.BodyMode):
	PhysicsServer3D.body_set_mode(rid, mode)


## Set the ragdoll mode of this character.
func set_ragdoll(ragdoll: bool):
	# FIXME: Something about this results in residual velocity.
	# Move, sit, stand -> character drifts
	set_body_mode(
		PhysicsServer3D.BODY_MODE_RIGID if ragdoll else PhysicsServer3D.BODY_MODE_KINEMATIC
	)

	is_ragdoll = ragdoll


## Get the [CharacterMotionProcessor] by the given [param id].
func get_motion_processor(id: StringName) -> CharacterMotionProcessor:
	for processor in _motion_processors:
		if processor.id == id:
			return processor
	return null


## Get whether the given [param state] is set on this processor.
func is_state(state: CharacterState) -> bool:
	return (self.state & state) == state


## Get whether this character is dead.
func is_dead() -> bool:
	return is_state(CharacterState.DEAD)


## Kill this character. Free its [member node] after [param timeout_s]
## (seconds). If [param callback] is not empty, it is called after the node is
## freed.
func die(timeout_s: float, callback := Callable()):
	queue_dead = true
	set_ragdoll(false)

	await node.get_tree().create_timer(timeout_s).timeout
	if is_instance_valid(node):
		node.queue_free()
		if callback != Callable():
			(callback as Callable).call()


## A class representing a point of contact with a wall-like object.
class WallInfo:
	extends RefCounted
	var point: Vector3
	var normal: Vector3
	var collider: Object


## A class representing the player's current motion inputs.
class Motion:
	extends RefCounted
	var direction := Vector2.ZERO
	var jump := false
	var run := false
	var sit := false

	var camera_rotation := Vector2.ZERO
	var camera_mode := CameraController.CameraMode.MODE_FIRST_PERSON


## A class representing the inputs and outputs of [CharacterMotionProcessor].
class Context:
	extends RefCounted
	# Input
	var motion := Motion.new()
	var input_direction := Vector3.ZERO
	var cam_basis_flat := Basis.IDENTITY

	# State
	var cancelled_processors: Dictionary[StringName, bool] = {}
	var cancelled_states := 0
	var messages: Dictionary[StringName, Variant] = {}

	# Output
	var new_state := 0
	var offset := Vector3.ZERO
	var new_basis := Basis.IDENTITY

	# Processor-specific output
	var is_grounded := false
	var ground_rid := RID()
	var ground_normal := Vector3.ZERO

	var walls: Array[WallInfo] = []
	var body_intersections: Array[CollisionObject3D] = []
	var area_intersections: Array[Area3D] = []

	var velocity := Vector3.ZERO

	## Reset the temporary components of this context. Run between frames.
	func reset():
		cancelled_processors.clear()
		cancelled_states = 0
		messages.clear()

		new_state = 0
		offset = Vector3.ZERO

		walls.clear()
		body_intersections.clear()
		area_intersections.clear()

		# The rest are reset externally.

	## Add a movement offset to this context.
	func add_offset(ofs: Vector3):
		offset += ofs

	## Add a state flag to this context.
	func set_state(state: CharacterState):
		new_state |= state

	## Cancel a future processor.
	func cancel_processor(id: StringName):
		cancelled_processors[id] = true

	## Cancel a state that doesn't make sense in this situation (e.g., WALKING
	## while CLIMBING).
	func cancel_state(state: CharacterState):
		cancelled_states |= state

	## Get the final state based on [member new_state] and
	## [member cancelled_states].
	func get_final_state() -> int:
		if new_state == CharacterState.NONE:
			return CharacterState.IDLE

		return new_state & ~cancelled_states
