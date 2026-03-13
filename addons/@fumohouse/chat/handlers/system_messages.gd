extends Node
## Handles system messages (e.g., player join and leave).

@onready var _nm := NetworkManager.get_singleton()
@onready var _cm := ChatManager.get_singleton()


func _ready():
	_nm.server_peer_joined.connect(_on_server_peer_joined)
	_nm.server_peer_disconnected.connect(_on_server_peer_disconnected)


func _on_server_peer_joined(peer: int):
	_cm.send_system_message("", 0, "%s joined" % _nm.get_peer_identity(peer))
	_cm.send_system_message("", peer, "Welcome to Fumohouse!")


func _on_server_peer_disconnected(peer: int):
	_cm.send_system_message("", 0, "%s left" % _nm.get_peer_identity(peer))
