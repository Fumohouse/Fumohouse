extends Control

const _BUTTON_SCENE := preload("player_button.tscn")

var _buttons: Dictionary[int, Button] = {}

@onready var _nm := NetworkManager.get_singleton()
@onready var _players: Control = %Players


func _ready():
	_nm.client_joined.connect(_on_client_joined)
	_nm.client_peer_joined.connect(_add_button)
	_nm.server_peer_joined.connect(_add_button)
	_nm.client_peer_disconnected.connect(_on_peer_disconnected)
	_nm.server_peer_disconnected.connect(_on_peer_disconnected)


func _on_client_joined():
	var self_btn: Button = _BUTTON_SCENE.instantiate()
	self_btn.text = _nm.local_identity
	_players.add_child(self_btn)
	for peer in _nm.get_peers():
		if peer == 1:
			continue
		_add_button(peer)


func _on_peer_disconnected(peer: int):
	var btn: Button = _buttons.get(peer, null)
	if btn:
		btn.queue_free()
		_buttons.erase(peer)


func _add_button(peer: int):
	var btn: Button = _BUTTON_SCENE.instantiate()
	btn.text = _nm.get_peer_identity(peer)
	_players.add_child(btn)
	_buttons[peer] = btn
