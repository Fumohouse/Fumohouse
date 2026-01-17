extends NetworkPacket
## Bidirectional. Client-origin: Request character spawn. Server-origin: Remote
## character spawn.

const ID: PackedByteArray = [0x40]

## Peer that is the subject of this packet.
var peer := 0
## The character's initial transform.
var transform := Transform3D.IDENTITY
## The character's appearance.
var appearance := Appearance.new()


func _init():
	id = ID
	display_name = "CHRSPAWN"


func _serde(serde: SerDe):
	peer = serde.varuint(peer)
	transform = serde.transform_3d(transform)
	appearance.serde(serde)
