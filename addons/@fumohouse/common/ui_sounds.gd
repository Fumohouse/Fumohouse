extends Node

var _audio_player_select: AudioStreamPlayer
var _audio_player_hover: AudioStreamPlayer
var _audio_player_type: AudioStreamPlayer
var _audio_player_tactile: AudioStreamPlayer

var scroll_pressed: bool

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
	
	_audio_player_tactile = AudioStreamPlayer.new()
	_audio_player_tactile.stream = load("res://addons/@fumohouse/common/assets/sounds/tactile_soft.ogg")
	_audio_player_tactile.bus = &"UI"
	_audio_player_tactile.volume_linear = 0.3
	_audio_player_tactile.pitch_scale = 1.5
	add_child(_audio_player_tactile)


func _play_select():
	_audio_player_select.play()


func _play_text_select(arg):
	_audio_player_select.play()


func _play_hover():
	_audio_player_hover.play()
	
	
func _play_scroll_hover(value):
	if scroll_pressed:
		_audio_player_hover.play()


func _scroll_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			scroll_pressed = true
		else:
			scroll_pressed = false


func _play_type(event):
	if event is InputEventKey and event.pressed:
		_audio_player_type.play()


func _play_exit():
	_audio_player_type.play()


func _play_tactile_arg(arg):
	_audio_player_tactile.play()


func _attach_button(button: Button):
	button.pressed.connect(_play_select)
	button.mouse_entered.connect(_play_hover)


func _attach_slider(slider: Slider):
	slider.mouse_entered.connect(_play_hover)
	slider.drag_started.connect(_play_select)
	slider.gui_input.connect(_scroll_input)
	slider.value_changed.connect(_play_scroll_hover)


func _attach_line_edit(textbox: LineEdit):
	textbox.text_submitted.connect(_play_text_select)
	textbox.mouse_entered.connect(_play_hover)
	textbox.gui_input.connect(_play_type)


func _attach_colour_picker_button(colour_picker_button: ColorPickerButton):
	colour_picker_button.popup_closed.connect(_play_exit)


func _attach_colour_picker(colour_picker: ColorPicker):
	colour_picker.color_changed.connect(_play_tactile_arg)


func _on_node_added(node: Node):
	if node.is_in_group("ui_sounds_exclude"):
		return
	if node.is_class("ColorPickerButton"):
		_attach_button(node)
		_attach_colour_picker_button(node)
	elif node.is_class("ColorPicker"):
		_attach_colour_picker(node)
	elif node.is_class("LineEdit"):
		_attach_line_edit(node)
	elif node.is_class("Slider"):
		_attach_slider(node)
	elif node.is_class("Button"):
		_attach_button(node)
