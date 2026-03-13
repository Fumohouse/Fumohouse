extends NetworkPacket
## Client to server: Send a chat message.

const ID: PackedByteArray = [0x50]

## An ID for this chat message for the [code]CHATACK[/code] response. Should be unique among
## currently in-flight messages.
var msg_id := 0
## Content of the chat message.
var content := ""


func _init():
	id = ID
	display_name = "CHATREQ"


func _serde(serde: SerDe):
	msg_id = serde.varuint(msg_id)
	content = serde.str(content)
