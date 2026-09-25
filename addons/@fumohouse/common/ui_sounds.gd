extends Node

const _SLIDER_DEBOUNCE_TIME := 0.1

var _audio_player_select: AudioStreamPlayer
var _audio_player_hover: AudioStreamPlayer
var _audio_player_type: AudioStreamPlayer
var _audio_player_colour_changed: AudioStreamPlayer
var _audio_player_colour_closed: AudioStreamPlayer

var _current_slider: Slider
var _slider_debounce: Timer

var _attached: Dictionary[Node, bool] = {}


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)

	_audio_player_select = AudioStreamPlayer.new()
	_audio_player_select.stream = load("res://addons/@fumohouse/common/assets/sounds/select.ogg")
	_audio_player_select.bus = &"UI"
	add_child(_audio_player_select)

	_audio_player_hover = AudioStreamPlayer.new()
	_audio_player_hover.stream = load("res://addons/@fumohouse/common/assets/sounds/hover.ogg")
	_audio_player_hover.bus = &"UI"
	add_child(_audio_player_hover)

	_audio_player_type = AudioStreamPlayer.new()
	_audio_player_type.stream = load("res://addons/@fumohouse/common/assets/sounds/type.ogg")
	_audio_player_type.bus = &"UI"
	add_child(_audio_player_type)

	_audio_player_colour_changed = AudioStreamPlayer.new()
	_audio_player_colour_changed.stream = load(
		"res://addons/@fumohouse/common/assets/sounds/colour_changed.ogg"
	)
	_audio_player_colour_changed.bus = &"UI"
	_audio_player_colour_changed.volume_linear = 0.5
	_audio_player_colour_changed.pitch_scale = 1.5
	add_child(_audio_player_colour_changed)

	_audio_player_colour_closed = AudioStreamPlayer.new()
	_audio_player_colour_closed.stream = load(
		"res://addons/@fumohouse/common/assets/sounds/colour_closed.ogg"
	)
	_audio_player_colour_closed.bus = &"UI"
	add_child(_audio_player_colour_closed)

	_slider_debounce = Timer.new()
	_slider_debounce.one_shot = true
	add_child(_slider_debounce)


func _on_slider_value_changed(value: float, slider: Slider):
	if _slider_debounce.time_left > 0.0:
		return

	# Heuristic for user input
	if (
		slider == _current_slider
		or (get_viewport().gui_get_focus_owner() == slider and Input.is_anything_pressed())
	):
		_audio_player_hover.play()
		_slider_debounce.start(_SLIDER_DEBOUNCE_TIME)


func _on_drag_started(slider: Slider):
	_current_slider = slider
	_slider_debounce.stop()


func _on_drag_ended(_value_changed: bool):
	_current_slider = null


func _on_textbox_text_changed(_new_text: String):
	_audio_player_type.play()


func _on_textbox_submitted(_text: String):
	_audio_player_select.play()


func _on_colour_picker_changed(value: Color):
	_audio_player_colour_changed.play()


func _attach_button(button: Button):
	button.pressed.connect(_audio_player_select.play)
	button.mouse_entered.connect(_audio_player_hover.play)


func _detach_button(button: Button):
	button.pressed.disconnect(_audio_player_select.play)
	button.mouse_entered.disconnect(_audio_player_hover.play)


func _attach_slider(slider: Slider):
	slider.mouse_entered.connect(_audio_player_hover.play)
	slider.drag_started.connect(_on_drag_started.bind(slider))
	slider.drag_ended.connect(_on_drag_ended)
	slider.value_changed.connect(_on_slider_value_changed.bind(slider))


func _detach_slider(slider: Slider):
	slider.mouse_entered.disconnect(_audio_player_hover.play)
	slider.drag_started.disconnect(_on_drag_started.bind(slider))
	slider.drag_ended.disconnect(_on_drag_ended)
	slider.value_changed.disconnect(_on_slider_value_changed.bind(slider))


func _attach_line_edit(textbox: LineEdit):
	textbox.text_submitted.connect(_on_textbox_submitted)
	textbox.mouse_entered.connect(_audio_player_hover.play)
	# text_changed does not get emitted when text is set programmatically
	textbox.text_changed.connect(_on_textbox_text_changed)


func _detach_line_edit(textbox: LineEdit):
	textbox.text_submitted.disconnect(_on_textbox_submitted)
	textbox.mouse_entered.disconnect(_audio_player_hover.play)
	textbox.text_changed.disconnect(_on_textbox_text_changed)


func _attach_colour_picker_button(colour_picker_button: ColorPickerButton):
	colour_picker_button.popup_closed.connect(_audio_player_colour_closed.play)


func _detach_colour_picker_button(colour_picker_button: ColorPickerButton):
	colour_picker_button.popup_closed.disconnect(_audio_player_colour_closed.play)


func _attach_colour_picker(colour_picker: ColorPicker):
	colour_picker.color_changed.connect(_on_colour_picker_changed)


func _detach_colour_picker(colour_picker: ColorPicker):
	colour_picker.color_changed.disconnect(_on_colour_picker_changed)


func _on_node_added(node: Node):
	if node.is_in_group("ui_sounds_exclude"):
		return
	if node is ColorPickerButton:
		_attach_button(node)
		_attach_colour_picker_button(node)
	elif node is ColorPicker:
		_attach_colour_picker(node)
	elif node is LineEdit:
		_attach_line_edit(node)
	elif node is Slider:
		# Ignore color picker sliders
		var parent: Node = node.get_parent()
		while parent:
			if parent is ColorPicker:
				return
			parent = parent.get_parent()

		_attach_slider(node)
	elif node is Button:
		_attach_button(node)
	else:
		return

	_attached[node] = true


func _on_node_removed(node: Node):
	if node.is_in_group("ui_sounds_exclude") or node not in _attached:
		return
	if node is ColorPickerButton:
		_detach_button(node)
		_detach_colour_picker_button(node)
	elif node is ColorPicker:
		_detach_colour_picker(node)
	elif node is LineEdit:
		_detach_line_edit(node)
	elif node is Slider:
		_detach_slider(node)
	elif node is Button:
		_detach_button(node)

	_attached.erase(node)
