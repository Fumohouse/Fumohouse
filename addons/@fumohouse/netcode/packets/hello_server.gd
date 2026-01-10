extends NetworkPacket
## Server to client: Acknowledge join, request to authenticate.

const ID: PackedByteArray = [0x00]

## Authentication type requested from the client.
var auth_type: NetworkManager.AuthType = NetworkManager.AuthType.NONE


func _init():
	id = ID
	display_name = "HELLOS"


func _serde(serde: SerDe):
	auth_type = serde.varuint(auth_type)
