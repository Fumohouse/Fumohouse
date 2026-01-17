extends NetworkPacket
## Bidirectional. Client-origin: Request new appearance. Server-origin: Remote
## character appearance changed.

const ID: PackedByteArray = [0x43]

## Peer that is the subject of this packet.
var peer := 0
## The appearance.
var appearance := Appearance.new()


func _init():
	id = ID
	display_name = "CHRAPR"


func _serde(serde: SerDe):
	peer = serde.varuint(peer)
	appearance.serde(serde)
