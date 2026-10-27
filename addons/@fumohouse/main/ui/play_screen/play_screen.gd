extends "res://addons/@fumohouse/navigation/screen_base.gd"

const WorldCard = preload("world_card.gd")
const _WORLD_CARD_SCENE = preload("world_card.tscn")
const FavoriteCard = preload("favorite_card.gd")
const _FAVORITE_CARD_SCENE = preload("favorite_card.tscn")

const StatusPopup := preload("res://addons/@fumohouse/navigation/components/status_popup.gd")

@onready var _wm := WorldManager.get_singleton()
@onready var _nm := NetworkManager.get_singleton()
@onready var _cm := ConfigManager.get_singleton()

@onready var _status_popup: StatusPopup = %StatusPopup
@onready var _world_list: Control = %WorldList
@onready var _favorite_list: Control = %FavoriteList

@onready var _note: LineEdit = %Note
@onready var _address: LineEdit = %Address
@onready var _port: SpinBox = %Port
@onready var _username: LineEdit = %Username
@onready var _password: LineEdit = %Password
@onready var _join_button: Button = %JoinButton
@onready var _favorite_button: Button = %FavoriteButton


func _ready():
	super()

	_join_button.pressed.connect(_on_join_button_pressed)
	_favorite_button.pressed.connect(_on_favorite_button_pressed)
	_wm.status_update.connect(_on_status_update)
	_nm.status_update.connect(_on_status_update)
	_cm.value_changed.connect(_on_config_change)

	_refresh_worlds()
	_refresh_favorites()


func _refresh_worlds():
	var worlds: Array[WorldManifest] = _wm.get_worlds()
	worlds.sort_custom(
		func(a: WorldManifest, b: WorldManifest):
			return a.display_name.naturalnocasecmp_to(b.display_name) < 0
	)

	for world in worlds:
		var card: WorldCard = _WORLD_CARD_SCENE.instantiate()
		card.world = world

		_world_list.add_child(card)


func _refresh_favorites():
	for favoritecard in _favorite_list.get_children():
		favoritecard.queue_free()

	var favorites: Array[Dictionary] = _cm.get_opt(&"favorites/servers")

	for favorite in favorites:
		var card: FavoriteCard = _FAVORITE_CARD_SCENE.instantiate()
		card.info = favorite
		card.edit_pressed.connect(_on_edit_pressed.bind(card.info))

		_favorite_list.add_child(card)


func _allow_join(state := true):
	_join_button.disabled = not state

	for favorite: FavoriteCard in _favorite_list.get_children():
		favorite.allow_join(state)


func _on_join_button_pressed():
	if _username.text.is_empty():
		return

	var address: String = "127.0.0.1" if _address.text.is_empty() else _address.text
	_wm.join_multiplayer_server(address, _port.value, _username.text, _password.text)


func _on_favorite_button_pressed():
	if _username.text.is_empty():
		return

	var info: Dictionary = {
		"note": _note.text if not _note.text.is_empty() else "Fumohouse Server",
		"address": _address.text if not _address.text.is_empty() else "127.0.0.1",
		"port": int(_port.value),
		"username": _username.text,
		"password": _password.text,
	}

	# Need to dupe as set_opt() doesn't work well with reference types
	var favorites: Array[Dictionary] = _cm.get_opt(&"favorites/servers").duplicate()
	favorites.append(info)
	_cm.set_opt(&"favorites/servers", favorites)


func _on_edit_pressed(info: Dictionary):
	_note.text = info["note"]
	_address.text = info["address"]
	_port.value = info["port"]
	_username.text = info["username"]
	_password.text = info["password"]


func _on_config_change(key: StringName):
	if key != &"favorites/servers":
		return

	_refresh_favorites()


func _on_status_update(msg: String, failure: bool):
	_status_popup.show()
	_status_popup.details_text = msg
	_allow_join(false)

	if failure:
		_status_popup.heading_text = "Failed"
		await get_tree().create_timer(3.0).timeout
		_status_popup.hide()
		_allow_join()
	else:
		_status_popup.heading_text = "Please wait…"
