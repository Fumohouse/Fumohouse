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

## Fired when this character should make a request to the server to move. The
## networking logic is not implemented here.
signal movement_request(motion: NetworkedMotion)

## Fired every time a movement update is available from the server. Should
## eventually result in updated information for the client this character
## belongs to and all other peers.
signal movement_update(ack: int)

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

## Represents what type of multiplayer character this is.
enum MultiplayerMode {
	## Singleplayer mode.
	SINGLEPLAYER = 0,
	## Multiplayer: This Godot instance is acting as server.
	MULTIPLAYER_SERVER = 1,
	## Multiplayer: This is the local character.
	MULTIPLAYER_LOCAL = 2,
	## Multiplayer: This is not the local character.
	MULTIPLAYER_REMOTE = 3,
}

## Get whether this is a multiplayer character that isn't the local one.
var is_remote: bool:
	get:
		return multiplayer_mode == MultiplayerMode.MULTIPLAYER_REMOTE

# MANAGED EXTERNALLY #
# All of these properties must be set externally prior to [method initialize].
## This character's multiplayer mode.
var multiplayer_mode: MultiplayerMode = MultiplayerMode.SINGLEPLAYER
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

# MULTIPLAYER #
var _motion_queue: Array[NetworkedMotion] = []
var _queued_valid := false
var _queued_transform := Transform3D.IDENTITY
var _queued_state := PackedByteArray()
var _queued_ack := 0


## Initialize this state. Prior to calling this function, set all externally
## managed configuration variables such as [member node] and [member rid].
func initialize():
	set_ragdoll(false)

	var is_server := multiplayer_mode == MultiplayerMode.MULTIPLAYER_SERVER

	if not is_remote:
		add_processor(CharacterIntersectionsMotionProcessor.new())
		add_processor(CharacterGroundingMotionProcessor.new())

	if not is_server:
		add_processor(CharacterInterpolatorMotionProcessor.new())

	add_processor(CharacterRagdollMotionProcessor.new())
	add_processor(CharacterLadderMotionProcessor.new())
	if not is_remote:
		add_processor(CharacterSwimMotionProcessor.new())

	add_processor(CharacterHorizontalMotionProcessor.new())
	if not is_remote:
		add_processor(CharacterPhysicalMotionProcessor.new())
		add_processor(CharacterPlatformMotionProcessor.new())
		add_processor(CharacterCollisionMotionProcessor.new())

	add_processor(CharacterMoveMotionProcessor.new())


## Add [param processor] to this motion state.
func add_processor(processor: CharacterMotionProcessor):
	_motion_processors.append(processor)
	processor.state = self
	processor._initialize()


## Perform the given motion, with behavior defined by [member multiplayer_mode].
## Call during physics process. On server, [param motion] is ignored.
func update(motion: Motion, delta: float):
	_handle_queued_update(delta)

	if multiplayer_mode == MultiplayerMode.SINGLEPLAYER:
		if not motion:
			return

		motion_update(motion, delta)
	elif multiplayer_mode == MultiplayerMode.MULTIPLAYER_LOCAL:
		if not motion:
			return

		var net_motion := NetworkedMotion.new()
		net_motion.motion = motion
		net_motion.ack = Engine.get_physics_frames()
		_motion_queue.push_back(net_motion)

		# Client side prediction
		motion_update(motion, delta)
		movement_request.emit(net_motion)
	elif multiplayer_mode == MultiplayerMode.MULTIPLAYER_SERVER:
		const MAX_QUEUE_SIZE := 4  # leave some buffer

		while true:
			var q_motion: NetworkedMotion = _motion_queue.pop_front()
			if not q_motion:
				break

			var actual_motion: Motion = q_motion.motion

			if is_dead():
				# Client sends nothing, but reset anyway in case hacking
				actual_motion.direction = Vector2.ZERO
				actual_motion.jump = false
				actual_motion.run = false
				actual_motion.sit = false

			motion_update(actual_motion, delta)
			movement_update.emit(q_motion.ack)

			if _motion_queue.size() <= MAX_QUEUE_SIZE:
				break
	elif multiplayer_mode == MultiplayerMode.MULTIPLAYER_REMOTE:
		motion_update(Motion.new(), delta, false, true)


## Queue a motion request for this character (for server processing).
func queue_motion(motion: NetworkedMotion):
	_motion_queue.push_back(motion)


## Queue a state update for this character (for client processing). The update
## will be applied during physics process using [method update].
func queue_update(transform: Transform3D, state: PackedByteArray, ack: int):
	if (
		multiplayer_mode == MultiplayerMode.MULTIPLAYER_LOCAL
		and (_motion_queue.is_empty() or ack < _motion_queue[0].ack)
	):
		return

	_queued_transform = transform
	_queued_state = state
	_queued_ack = ack
	_queued_valid = true


## Update this character's motion. If [param is_replay] is [code]true[/code],
## this is a replay of a previous motion (e.g., for server reconciliation). If
## [param persist_state] is [code]true[/code], persist the last known state
## (e.g., for remote characters).
func motion_update(motion: Motion, delta: float, is_replay := false, persist_state := false):
	var orig_transform := node.global_transform

	# Reset and initialize context
	ctx.reset()
	ctx.motion = motion
	ctx.input_direction = Vector3(motion.direction.x, 0, motion.direction.y)
	ctx.cam_basis_flat = Basis.IDENTITY.rotated(Vector3.UP, motion.camera_rotation.y)

	ctx.new_basis = orig_transform.basis

	ctx.is_replay = is_replay

	# Persist death
	if queue_dead or is_state(CharacterState.DEAD):
		ctx.set_state(CharacterState.DEAD)
		queue_dead = false

	if persist_state:
		ctx.new_state = state

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
		if callback.is_valid():
			(callback as Callable).call()


## Encode this object's state and its processors' state to a buffer.
func get_state() -> PackedByteArray:
	var ser := Serializer.new([])
	_serde_state(ser)

	var proc_states: Dictionary[StringName, PackedByteArray] = {}

	var ser2 := Serializer.new([])
	for processor in _motion_processors:
		ser2.seek(0)
		processor._state_serde(ser2)
		if ser2.pos == 0:
			continue

		proc_states[processor.id] = ser2.to_buffer()

	ser.varuint(proc_states.size())
	for proc_name in proc_states:
		ser.str(proc_name)
		ser.sized_buffer(proc_states[proc_name])

	return ser.to_buffer()


## Load this object's state and its processors' state from a buffer.
func load_state(buf: PackedByteArray):
	var de := Deserializer.new(buf)
	_serde_state(de)

	var num_procs: int = de.varuint()
	for i in num_procs:
		var proc: CharacterMotionProcessor = get_motion_processor(de.str())
		var proc_state_buf: PackedByteArray = de.sized_buffer([])
		if not proc:
			continue

		proc._state_serde(Deserializer.new(proc_state_buf))


func _serde_state(serde: SerDe):
	state = serde.varuint(state)
	# something about this code is demonic
	var ragdoll: bool = serde.boolean(is_ragdoll)
	if ragdoll != is_ragdoll:
		set_ragdoll(ragdoll)
	if is_ragdoll:
		node.linear_velocity = serde.vector3(node.linear_velocity)
		node.angular_velocity = serde.vector3(node.angular_velocity)


func _ack_queue(ack: int):
	var i := 0
	while i < _motion_queue.size() and _motion_queue[i].ack <= ack:
		i += 1

	_motion_queue = _motion_queue.slice(i)


func _handle_queued_update(delta: float):
	if not _queued_valid:
		return

	load_state(_queued_state)

	var interpolator: CharacterInterpolatorMotionProcessor = get_motion_processor(
		CharacterInterpolatorMotionProcessor.ID
	)

	if multiplayer_mode == MultiplayerMode.MULTIPLAYER_LOCAL:
		# Perform rollback
		var initial_transform := node.global_transform
		node.global_transform = _queued_transform

		_ack_queue(_queued_ack)

		for motion in _motion_queue:
			motion_update(motion.motion, delta, true)

		var target_transform := node.global_transform
		node.global_transform = initial_transform

		interpolator.set_target(target_transform)
	else:
		interpolator.set_target(_queued_transform)

	_queued_valid = false


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


## A class representing a single networked motion request (for client side
## prediction and server reconciliation).
class NetworkedMotion:
	extends RefCounted
	var motion := Motion.new()
	var ack := 0


## A class representing the inputs and outputs of [CharacterMotionProcessor].
class Context:
	extends RefCounted
	# Input
	var motion := Motion.new()
	var input_direction := Vector3.ZERO
	var cam_basis_flat := Basis.IDENTITY
	var is_replay := false

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
