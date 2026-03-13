extends NetworkPacket
## Server to client: Chat message.

const ID: PackedByteArray = [0x50]

## A string representing who sent the message. May be empty (e.g., for system
## messages).
var sender := ""
## The peer ID (if any) who sent this message. If zero, the peer is undefined.
var peer := 0
## Content of the chat message.
var content := ""


func _init():
	id = ID
	display_name = "CHATTED"


func _serde(serde: SerDe):
	sender = serde.str(sender)
	peer = serde.varuint(peer)
	content = serde.str(content)
