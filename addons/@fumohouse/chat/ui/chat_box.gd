extends LineEdit

var _last_text_size := 0

@onready var _edb := EmojiDatabase.get_singleton()
@onready var _chat := ChatManager.get_singleton()
@onready var _config := ConfigManager.get_singleton()


func _ready():
	text_changed.connect(_on_changed)
	text_submitted.connect(_on_submit)

	_update_placeholder.call_deferred()
	_config.value_changed.connect(_on_config_value_changed)


func _gui_input(event: InputEvent):
	if event.is_action_pressed(&"menu_back"):
		clear()
		release_focus()
		accept_event()


func _input(event: InputEvent):
	if has_focus():
		# https://forum.godotengine.org/t/how-to-click-out-of-line-edit/22591/5
		if event is InputEventMouseButton and not get_global_rect().has_point(event.position):
			release_focus()
	else:
		if event.is_action_pressed(&"chat"):
			grab_focus()
			get_viewport().set_input_as_handled()


func _on_changed(new_text: String):
	var sz := new_text.length()
	if sz == 0:
		_last_text_size = 0
		return

	var col: int = caret_column

	if sz > _last_text_size and col >= 2 and col <= sz:
		var char := new_text[col - 1]
		if char == ":":
			var matching: int = new_text.rfind(":", col - 2)
			if matching >= 0:
				var substr: String = new_text.substr(matching + 1, col - matching - 2)
				var emoji: String = _edb.get_by_short_code(substr)
				if not emoji.is_empty():
					text = text.substr(0, matching) + emoji + text.substr(col)
					caret_column = col - (substr.length() - emoji.length() + 2)

	_last_text_size = sz


func _on_submit(new_text: String):
	if not text.is_empty():
		_chat.send_chat(text)

	clear()
	release_focus()


func _update_placeholder():
	var evt: InputEvent = _config.get_opt(&"input/action/chat/bind")
	var input_text: String = "Unknown"
	if evt is InputEventKey:
		input_text = evt.as_text_physical_keycode()
	elif evt is InputEventMouse:
		input_text = evt.as_text()

	placeholder_text = ("Click here or press %s to chat…" % input_text)


func _on_config_value_changed(key: StringName):
	if key == &"input/action/chat/bind":
		_update_placeholder()
