extends NetworkPacket
## Bidirectional: Disconnect with reason.

const ID: PackedByteArray = [0x01]

## Disconnection reason.
var reason := ""


func _init():
	id = ID
	display_name = "GOODBYE"


func _serde(serde: SerDe):
	reason = serde.str(reason)
