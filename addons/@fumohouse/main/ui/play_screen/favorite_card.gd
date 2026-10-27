extends PanelContainer

## Emitted when pressing the Edit button.
signal edit_pressed

## Information about the server to display, loaded on ready.
var info: Dictionary

@onready var _cm := ConfigManager.get_singleton()
@onready var _wm := WorldManager.get_singleton()

@onready var _name: Label = %Name
@onready var _description: RichTextLabel = %Description
@onready var _join_button: Button = %JoinButton
@onready var _edit_button: Button = %EditButton
@onready var _delete_button: Button = %DeleteButton


func _ready():
	if (
		info["name"] is not String
		or info["address"] is not String
		or info["port"] is not int
		or info["username"] is not String
		or info["password"] is not String
	):
		return

	_name.text = info["name"]
	_description.text = "Join as '{0}'".format([info["username"]])

	_join_button.pressed.connect(_on_join_button_pressed)
	_edit_button.pressed.connect(edit_pressed.emit)
	_delete_button.pressed.connect(_on_delete_button_pressed)


## Enables/disables the join button.
func allow_join(state := true):
	_join_button.disabled = not state


func _on_join_button_pressed():
	if info["username"].is_empty():
		return

	_wm.join_multiplayer_server(info["address"], info["port"], info["username"], info["password"])


func _on_delete_button_pressed():
	# Need to dupe as set_opt() doesn't work well with reference types
	var favorites: Array[Dictionary] = _cm.get_opt(&"favorites/servers").duplicate()
	favorites.remove_at(get_index())
	_cm.set_opt(&"favorites/servers", favorites)
