class_name ColorPickerButtonSound

extends ColorPickerButton


#@export var audio_player: AudioStream

@export var _audio_player_press: AudioStreamPlayer
@export var _audio_player_hover: AudioStreamPlayer
@export var _audio_player_changed: AudioStreamPlayer
@export var _audio_player_closed: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_audio_player_press = AudioStreamPlayer.new()
	_audio_player_press.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/select.ogg")
	_audio_player_press.bus = &"UI"
	button_down.connect(_button_pressed)
	add_child(_audio_player_press)

	_audio_player_hover = AudioStreamPlayer.new()
	_audio_player_hover.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/hover.ogg")
	_audio_player_hover.bus = &"UI"
	mouse_entered.connect(_button_mouse_entered)
	add_child(_audio_player_hover)

	_audio_player_changed = AudioStreamPlayer.new()
	_audio_player_changed.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/pop.ogg")
	_audio_player_changed.bus = &"UI"
	color_changed.connect(_pop)
	add_child(_audio_player_changed)
	
	_audio_player_closed = AudioStreamPlayer.new()
	_audio_player_closed.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/pop.ogg")
	_audio_player_closed.bus = &"UI"
	popup_closed.connect(_close)
	add_child(_audio_player_closed)

func _button_pressed():
	_audio_player_press.play()
	
func _button_mouse_entered():
	_audio_player_hover.play()
	
func _pop(color):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)&& !Input.CURSOR_DRAG:
		_audio_player_changed.play()
	
func _close():
	_audio_player_changed.play()
