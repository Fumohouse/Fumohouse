extends NetworkPacket
## Client to server: Provide authentication details.

const ID: PackedByteArray = [0x02]

## Authentication data (if requested).
var auth_data := ""


func _init():
	id = ID
	display_name = "AUTH"


func _serde(serde: SerDe):
	auth_data = serde.str(auth_data)
