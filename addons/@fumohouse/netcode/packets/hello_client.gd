extends NetworkPacket
## Client to server: Request to join.

const ID: PackedByteArray = [0x00]

## Client version, e.g., [code]20260102[/code].
var version := 0
## Client identity (i.e., username).
var identity := ""


func _init():
	id = ID
	display_name = "HELLOC"


func _serde(serde: SerDe):
	version = serde.varuint(version)
	identity = serde.str(identity)
