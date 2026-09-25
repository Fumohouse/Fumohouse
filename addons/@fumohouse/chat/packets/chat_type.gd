extends NetworkPacket
## Bidirectional: Client-origin: User started or stopped typing in chat.
## Server-origin: Broadcast of client typing notification.

const ID: PackedByteArray = [0x52]

## Peer that is the subject of this packet.
var peer := 0
## Typing status.
var status := false


func _init():
	id = ID
	display_name = "CHATTYPE"


func _serde(serde: SerDe):
	peer = serde.varuint(peer)
	status = serde.boolean(status)
