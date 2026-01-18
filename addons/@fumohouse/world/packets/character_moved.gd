extends NetworkPacket
## Server to client: Character movement update.

const ID: PackedByteArray = [0x44]

## Peer that is the subject of this packet.
var peer := 0
## Character state for this peer.
var state: CharacterManagerBase.CharacterState = CharacterManagerBase.CharacterState.new()
## Acknowledge number for movement packets. Should be zero when sending remote
## information.
var movement_ack := 0


func _init():
	id = ID
	display_name = "CHRMOVED"
	mode = MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
	channel = 1


func _serde(serde: SerDe):
	peer = serde.varuint(peer)

	state.transform = serde.transform_3d(state.transform)
	state.motion_state = serde.sized_buffer(state.motion_state)

	movement_ack = serde.varuint(movement_ack)
