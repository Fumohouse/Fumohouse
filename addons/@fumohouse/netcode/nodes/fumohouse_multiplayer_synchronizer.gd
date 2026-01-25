class_name FumohouseMultiplayerSynchronizer
extends MultiplayerSynchronizer
## A [MultiplayerSynchronizer] that automatically manages its visibility based
## on [NetworkManager] state.

@onready var _nm := NetworkManager.get_singleton()


func _ready():
	if not _nm.is_active or not _nm.is_server:
		return

	add_visibility_filter(
		func(peer: int) -> bool: return _nm.get_peer_state(peer) >= NetworkManager.PeerState.JOINED
	)
