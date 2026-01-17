extends NetworkPacket
## Bidirectional. Client-origin: Request character reset. Server-origin: Remote
## character death. This packet is not sent on player disconnect.

const ID: PackedByteArray = [0x41]

## Peer that is the subject of this packet.
var peer := 0
## If [code]true[/code], play the death animation. Otherwise, just delete the
## character.
var died := false


func _init():
	id = ID
	display_name = "CHRDEL"


func _serde(serde: SerDe):
	peer = serde.varuint(peer)
	died = serde.boolean(died)
