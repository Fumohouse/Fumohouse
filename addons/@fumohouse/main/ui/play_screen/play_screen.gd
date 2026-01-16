extends "res://addons/@fumohouse/navigation/screen_base.gd"

const WorldCard = preload("world_card.gd")
const _WORLD_CARD_SCENE = preload("world_card.tscn")

const StatusPopup := preload("res://addons/@fumohouse/navigation/components/status_popup.gd")

@onready var _wm := WorldManager.get_singleton()
@onready var _nm := NetworkManager.get_singleton()

@onready var _status_popup: StatusPopup = %StatusPopup
@onready var _world_list: Control = %WorldList

@onready var _address: LineEdit = %Address
@onready var _port: SpinBox = %Port
@onready var _username: LineEdit = %Username
@onready var _password: LineEdit = %Password
@onready var _join_button: Button = %JoinButton


func _ready():
	super()

	_join_button.pressed.connect(_on_join_button_pressed)
	_wm.status_update.connect(_on_status_update)
	_nm.status_update.connect(_on_status_update)

	_refresh()


func _on_join_button_pressed():
	if _username.text.is_empty():
		return

	_join_button.disabled = true
	var address: String = "127.0.0.1" if _address.text.is_empty() else _address.text
	_wm.join_multiplayer_server(address, _port.value, _username.text, _password.text)


func _refresh():
	var worlds: Array[WorldManifest] = _wm.get_worlds()
	worlds.sort_custom(
		func(a: WorldManifest, b: WorldManifest):
			return a.display_name.naturalnocasecmp_to(b.display_name) < 0
	)

	for world in worlds:
		var card: WorldCard = _WORLD_CARD_SCENE.instantiate()
		card.world = world

		_world_list.add_child(card)


func _on_status_update(msg: String, failure: bool):
	_status_popup.show()
	_status_popup.details_text = msg

	if failure:
		_status_popup.heading_text = "Failed"
		await get_tree().create_timer(3.0).timeout
		_status_popup.hide()
		_join_button.disabled = false
	else:
		_status_popup.heading_text = "Please wait…"
