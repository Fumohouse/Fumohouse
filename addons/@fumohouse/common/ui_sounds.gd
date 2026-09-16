extends Node

var _scene_tree: SceneTree

var _audio_player_select: AudioStreamPlayer
var _audio_player_hover: AudioStreamPlayer
var _audio_player_type: AudioStreamPlayer

var scroll_pressed: bool

#BUtton, Slider, colour picker, text input

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("ui_sounds: _ready() called!")
	_scene_tree = get_tree()
	
	_scene_tree.node_added.connect(_added)
	_scene_tree.node_removed.connect(_removed)
	
	_audio_player_select = AudioStreamPlayer.new()
	_audio_player_select.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/select.ogg")
	_audio_player_select.bus = &"UI"
	add_child(_audio_player_select)
	
	_audio_player_hover = AudioStreamPlayer.new()
	_audio_player_hover.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/hover.ogg")
	_audio_player_hover.bus = &"UI"
	add_child(_audio_player_hover)
	
	_audio_player_type = AudioStreamPlayer.new()
	_audio_player_type.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/type.ogg")
	_audio_player_type.bus = &"UI"
	add_child(_audio_player_type)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_select():
	_audio_player_select.play()

func play_text_select(arg):
	_audio_player_select.play()

func play_hover():
	_audio_player_hover.play()
	
func play_scroll_hover(value):
	if scroll_pressed:
		_audio_player_hover.play()

func scroll_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			scroll_pressed = true
		else:
			scroll_pressed = false

func play_type(event):
	if event is InputEventKey and event.pressed:
		_audio_player_type.play()

func attach_button(button: Button):
	button.pressed.connect(play_select)
	button.mouse_entered.connect(play_hover)

func attach_slider(slider: Slider):
	slider.mouse_entered.connect(play_hover)
	slider.drag_started.connect(play_select)
	slider.gui_input.connect(scroll_input)
	slider.value_changed.connect(play_scroll_hover)

func attach_line_edit(textbox: LineEdit):
	textbox.text_submitted.connect(play_text_select)
	textbox.mouse_entered.connect(play_hover)
	textbox.gui_input.connect(play_type)

func _added(node: Node):
	if node.is_in_group("ui_sounds_exclude"):
		return
	if node.is_class("Button"):
		attach_button(node)
	elif node.is_class("LineEdit"):
		attach_line_edit(node)
	elif node.is_class("Slider"):
		attach_slider(node)
	else:
		pass

func _removed(node):
		if node.is_class("Button"):
			pass#print("button trolved: ", node)
