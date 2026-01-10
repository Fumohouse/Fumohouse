extends NetworkPacket
## Server to client: Authentication success. Sync peer status on join.

const ID: PackedByteArray = [0x02]

## Map of peer data, excluding the one this packet is sent to.
var peers: Dictionary[int, NetworkManager.PeerData] = {}


func _init():
	id = ID
	display_name = "SYNC"


func _serde(serde: SerDe):
	# This logic kind of defeats the purpose but oh well
	var peer_count: int = serde.varuint(peers.size())

	if peers.is_empty():
		for i in peer_count:
			var peer_id: int = serde.varsint(0)
			var peer_data := NetworkManager.PeerData.new()

			peer_data.identity = serde.str("")

			peers[peer_id] = peer_data
	else:
		for peer_id in peers:
			serde.varsint(peer_id)

			var peer_data: NetworkManager.PeerData = peers[peer_id]
			serde.str(peer_data.identity)
