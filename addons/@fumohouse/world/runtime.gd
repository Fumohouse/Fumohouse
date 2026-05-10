class_name WorldRuntime
extends Node3D
## Node containing runtime components, including player characters, camera, and
## HUD.

const DebugCharacter := preload("res://addons/@fumohouse/character/debug_character.gd")
const Chat := preload("res://addons/@fumohouse/chat/ui/chat.gd")

const LOG_SCOPE := "WorldRuntime"
const SCREENSHOT_PATH := "user://screenshots"

## Camera to use for the local character.
@export var camera: CameraController
## Debug overlay to bind to the local character.
@export var debug_character: DebugCharacter

@onready var _nm := NetworkManager.get_singleton()
@onready var _cm := ChatManager.get_singleton()
@onready var _toggleable: Control = %Toggleable
@onready var _chat: Chat = %Chat
@onready var _player_list: Control = %PlayerList
@onready var _chat_button: Button = %ChatButton
@onready var _players_button: Button = %PlayersButton


func _ready():
	_on_chat_button_toggled(_chat_button.button_pressed)
	_chat_button.toggled.connect(_on_chat_button_toggled)

	if _nm.is_active:
		_on_players_button_toggled(_players_button.button_pressed)
		_players_button.toggled.connect(_on_players_button_toggled)
	else:
		_player_list.hide()
		_players_button.hide()


func _input(event: InputEvent):
	if event.is_action_pressed(&"player_list"):
		_players_button.button_pressed = not _players_button.button_pressed
		get_viewport().set_input_as_handled()

	if event.is_action_pressed(&"toggle_hud"):
		_toggleable.visible = not _toggleable.visible
		get_viewport().set_input_as_handled()

	if event.is_action_pressed(&"screenshot"):
		var img: Image = get_viewport().get_texture().get_image()
		var err := DirAccess.make_dir_absolute(SCREENSHOT_PATH)
		if err != OK and err != ERR_ALREADY_EXISTS:
			var msg := "Failed to create screenshot directory %s (%d)" % [error_string(err), err]
			_cm.send_local_message("", msg)
			Log.error(msg, LOG_SCOPE)
			return

		var file_name := Time.get_datetime_string_from_system().replace(":", "-") + ".png"
		err = img.save_png(SCREENSHOT_PATH.path_join(file_name))
		if err == OK:
			_cm.send_local_message(
				"",
				(
					"Screenshot saved as [url=%s]%s[/url]"
					% [SCREENSHOT_PATH.path_join(file_name), file_name]
				)
			)
		else:
			var msg := "Failed to save screenshot: %s (%d)" % [error_string(err), err]
			_cm.send_local_message("", msg)
			Log.error(msg, LOG_SCOPE)

		get_viewport().set_input_as_handled()


func _on_chat_button_toggled(toggled: bool):
	_chat.visible = toggled
	if toggled:
		_chat.refresh()


func _on_players_button_toggled(toggled: bool):
	_player_list.visible = toggled
