extends NetworkPacket
## Server to client: Sync the state of all currently online characters.

const ID: PackedByteArray = [0x42]

## Map of peer IDs to character state dictionary.
var state: Dictionary[int, CharacterManagerBase.CharacterState] = {}


func _init():
	id = ID
	display_name = "CHRSYN"


func _serde(serde: SerDe):
	# This logic kind of defeats the purpose but oh well
	var peer_count: int = serde.varuint(state.size())

	if state.is_empty():
		for i in peer_count:
			var peer_id: int = serde.varsint(0)
			var char_state := CharacterManagerBase.CharacterState.new()

			char_state.appearance = Appearance.new()
			char_state.appearance.serde(serde)
			char_state.transform = serde.transform_3d(Transform3D.IDENTITY)
			char_state.motion_state = serde.sized_buffer([])

			state[peer_id] = char_state
	else:
		for peer_id in state:
			serde.varsint(peer_id)
			var char_state: CharacterManagerBase.CharacterState = state[peer_id]

			char_state.appearance.serde(serde)
			serde.transform_3d(char_state.transform)
			serde.sized_buffer(char_state.motion_state)
