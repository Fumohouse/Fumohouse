extends Node

var _audio_player_select: AudioStreamPlayer
var _audio_player_hover: AudioStreamPlayer
var _audio_player_type: AudioStreamPlayer
var _audio_player_colour_changed: AudioStreamPlayer

var _current_slider: Slider

func _ready() -> void:
	
	get_tree().node_added.connect(_on_node_added)
	
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
	_audio_player_colour_changed.stream = load("res://addons/@fumohouse/common/assets/sounds/colour_changed.ogg")
	_audio_player_colour_changed.bus = &"UI"
	_audio_player_colour_changed.volume_linear = 0.3
	_audio_player_colour_changed.pitch_scale = 1.5
	add_child(_audio_player_colour_changed)


func _on_slider_hover(value):
	if _current_slider:
		_audio_player_hover.play()


func _on_drag_started(slider: Slider):
	_current_slider = slider


func _on_drag_ended(pls):
	_current_slider = null


func _on_textbox_gui_input(event):
	if event is InputEventKey and event.pressed:
		_audio_player_type.play()


func _attach_button(button: Button):
	button.pressed.connect(_audio_player_select.play)
	button.mouse_entered.connect(_audio_player_hover.play)


func _attach_slider(slider: Slider):
	slider.mouse_entered.connect(_audio_player_hover.play)
	slider.drag_started.connect(_audio_player_select.play)
	#slider.gui_input.connect(_scroll_input)
	slider.value_changed.connect(_on_slider_hover)
	
	slider.drag_started.connect(_on_drag_started.bind(slider))
	slider.drag_ended.connect(_on_drag_ended)


func _attach_line_edit(textbox: LineEdit):
	textbox.text_submitted.connect(_audio_player_select.play)
	textbox.mouse_entered.connect(_audio_player_hover.play)
	textbox.gui_input.connect(_on_textbox_gui_input)


func _attach_colour_picker_button(colour_picker_button: ColorPickerButton):
	colour_picker_button.popup_closed.connect(_audio_player_type.play)


func _attach_colour_picker(colour_picker: ColorPicker):
	colour_picker.color_changed.connect(
		func (value):
			_audio_player_colour_changed.play()
	)


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
		_attach_slider(node)
	elif node is Button:
		_attach_button(node)
