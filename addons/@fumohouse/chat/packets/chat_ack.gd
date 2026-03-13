extends NetworkPacket
## Server to client: Chat acknowledgment or non-acknowledgment.

const ID: PackedByteArray = [0x51]

## ID of the chat message.
var msg_id := 0
## Acknowledgment status of the chat message.
var status: ChatManager.ChatStatus = ChatManager.ChatStatus.OK


func _init():
	id = ID
	display_name = "CHATACK"


func _serde(serde: SerDe):
	msg_id = serde.varuint(msg_id)
	status = serde.varuint(status)
