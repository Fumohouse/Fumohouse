extends "res://addons/@fumohouse/navigation/screen_base.gd"

const WorldCard = preload("world_card.gd")
const _WORLD_CARD_SCENE = preload("world_card.tscn")
const FavoriteCard = preload("favorite_card.gd")
const _FAVORITE_CARD_SCENE = preload("favorite_card.tscn")

const ServerManifest := preload("res://addons/@fumohouse/common/resource_types/server_manifest.gd")
const StatusPopup := preload("res://addons/@fumohouse/navigation/components/status_popup.gd")

@onready var _wm := WorldManager.get_singleton()
@onready var _nm := NetworkManager.get_singleton()
@onready var _cm := ConfigManager.get_singleton()

@onready var _status_popup: StatusPopup = %StatusPopup
@onready var _world_list: Control = %WorldList
@onready var _favorite_list: Control = %FavoriteList

@onready var _name: LineEdit = %Name
@onready var _address: LineEdit = %Address
@onready var _port: SpinBox = %Port
@onready var _username: LineEdit = %Username
@onready var _password: LineEdit = %Password
@onready var _join_button: Button = %JoinButton
@onready var _favorite_button: Button = %FavoriteButton


func _ready():
	super()

	_join_button.pressed.connect(_on_join_button_pressed.bind(null))
	_favorite_button.pressed.connect(_on_favorite_button_pressed)
	_wm.status_update.connect(_on_status_update)
	_nm.status_update.connect(_on_status_update)
	_cm.value_changed.connect(_on_config_change)

	_refresh_worlds()
	_refresh_favorites()

	_username.text = _cm.get_opt(&"multiplayer/username")


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

	var favorites: Array[ServerManifest] = _cm.get_opt(&"multiplayer/favorites")

	for favorite in favorites:
		var card: FavoriteCard = _FAVORITE_CARD_SCENE.instantiate()
		card.info = favorite
		card.copy_pressed.connect(_on_copy_pressed.bind(card.info))
		card.join_pressed.connect(_on_join_button_pressed.bind(card.info))

		_favorite_list.add_child(card)


## Creates a [ServerManifest] from Quick Connect fields.
func _as_manifest() -> ServerManifest:
	var info := ServerManifest.new()
	if not _name.text.is_empty():
		info.name = _name.text
	if not _address.text.is_empty():
		info.address = _address.text
	info.port = int(_port.value)
	info.password = _password.text

	return info


func _allow_join(state := true):
	_join_button.disabled = not state

	for favorite: FavoriteCard in _favorite_list.get_children():
		favorite.allow_join(state)


func _on_join_button_pressed(info: ServerManifest):
	if _username.text.is_empty():
		return

	_cm.set_opt(&"multiplayer/username", _username.text)

	if info == null:
		info = _as_manifest()

	_wm.join_multiplayer_server(info.address, info.port, _username.text, info.password)


func _on_favorite_button_pressed():
	var info := _as_manifest()

	# Need to dupe as set_opt() doesn't work well with reference types
	var favorites: Array[ServerManifest] = _cm.get_opt(&"multiplayer/favorites").duplicate()
	favorites.append(info)
	_cm.set_opt(&"multiplayer/favorites", favorites)


func _on_copy_pressed(info: ServerManifest):
	_name.text = info.name
	_address.text = info.address
	_port.value = info.port
	_password.text = info.password


func _on_config_change(key: StringName):
	if key != &"multiplayer/favorites":
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
