extends NetworkPacket
## Server to client: Peer status update.

const ID: PackedByteArray = [0x03]

## Peer ID.
var peer := 0
## Peer identity.
var identity := ""
## Status message.
var status: NetworkManager.PeerStateUpdate = NetworkManager.PeerStateUpdate.JOINED


func _init():
	id = ID
	display_name = "PEER"


func _serde(serde: SerDe):
	peer = serde.varsint(peer)
	identity = serde.str(identity)
	status = serde.varuint(status)
