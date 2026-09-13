class_name SliderSound

extends Slider


@export var audio_player: AudioStream

var _audio_player_press: AudioStreamPlayer
var _audio_player_hover: AudioStreamPlayer

#if this is set to 0 all sliders will trigger on startup
var recent_press = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_audio_player_press = AudioStreamPlayer.new()
	_audio_player_press.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/select.ogg")
	_audio_player_press.bus = &"UI"
	
	drag_started.connect(button_pressed)
	mouse_entered.connect(hover)
	add_child(_audio_player_press)

	_audio_player_hover = AudioStreamPlayer.new()
	_audio_player_hover.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/hover.ogg")
	_audio_player_hover.bus = &"UI"
	add_child(_audio_player_hover)
	

func button_pressed():
	_audio_player_press.play()
	recent_press = 1

func hover():
	_audio_player_hover.play()


func _value_changed(new_value: float) -> void:
	if recent_press != 1:
		_audio_player_hover.play()
	recent_press = 0
