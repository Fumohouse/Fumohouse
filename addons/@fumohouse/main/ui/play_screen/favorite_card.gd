extends PanelContainer

## Emitted when pressing the Copy button.
signal copy_pressed
## Emitted when pressing the Join button.
signal join_pressed

const ServerManifest := preload("res://addons/@fumohouse/common/resource_types/server_manifest.gd")

## Information about the server to display, loaded on ready.
var info: ServerManifest

@onready var _cm := ConfigManager.get_singleton()
@onready var _wm := WorldManager.get_singleton()

@onready var _name: Label = %Name
@onready var _description: RichTextLabel = %Description
@onready var _join_button: Button = %JoinButton
@onready var _copy_button: Button = %CopyButton
@onready var _delete_button: Button = %DeleteButton


func _ready():
	_name.text = info.name

	_join_button.pressed.connect(join_pressed.emit)
	_copy_button.pressed.connect(copy_pressed.emit)
	_delete_button.pressed.connect(_on_delete_button_pressed)


## Enables/disables the join button.
func allow_join(state := true):
	_join_button.disabled = not state


func _on_delete_button_pressed():
	# Need to dupe as set_opt() doesn't work well with reference types
	var favorites: Array[ServerManifest] = _cm.get_opt(&"multiplayer/favorites").duplicate()
	favorites.remove_at(get_index())
	_cm.set_opt(&"multiplayer/favorites", favorites)
