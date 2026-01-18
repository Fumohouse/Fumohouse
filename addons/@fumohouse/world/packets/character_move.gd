extends NetworkPacket
## Client to server: Character movement request.

const ID: PackedByteArray = [0x44]

## Motion data.
var motion := CharacterMotionState.NetworkedMotion.new()


func _init():
	id = ID
	display_name = "CHRMOVE"
	mode = MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
	channel = 1


func _serde(serde: SerDe):
	motion.ack = serde.varuint(motion.ack)

	var actual_motion: CharacterMotionState.Motion = motion.motion

	var motion_flags_value := 0
	if actual_motion.jump:
		motion_flags_value |= 1
	if actual_motion.run:
		motion_flags_value |= 2
	if actual_motion.sit:
		motion_flags_value |= 4

	var idle_value := actual_motion.direction == Vector2.ZERO and motion_flags_value == 0
	var idle := serde.boolean(idle_value)
	if not idle:
		actual_motion.direction = serde.vector2(actual_motion.direction)
		var motion_flags: int = serde.varuint(motion_flags_value)
		if motion_flags & 1:
			actual_motion.jump = true
		if motion_flags & 2:
			actual_motion.run = true
		if motion_flags & 4:
			actual_motion.sit = true

	actual_motion.camera_rotation = serde.vector2(actual_motion.camera_rotation)
	actual_motion.camera_mode = serde.varuint(actual_motion.camera_mode)
