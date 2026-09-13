class_name ButtonSound

extends Button


@export var audio_player: AudioStream

var _audio_player_press: AudioStreamPlayer
var _audio_player_hover: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_audio_player_press = AudioStreamPlayer.new()
	_audio_player_press.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/select.ogg")
	_audio_player_press.bus = &"UI"
	pressed.connect(_button_pressed)
	add_child(_audio_player_press)

	_audio_player_hover = AudioStreamPlayer.new()
	_audio_player_hover.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/hover.ogg")
	_audio_player_hover.bus = &"UI"
	mouse_entered.connect(_button_mouse_entered)
	add_child(_audio_player_hover)


func _button_pressed():
	_audio_player_press.play()
	
func _button_mouse_entered():
	_audio_player_hover.play()
	
