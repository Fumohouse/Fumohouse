class_name SliderSoundTts

extends Slider


@export var audio_player: AudioStream

var _audio_player_press: AudioStreamPlayer
var _audio_player_hover: AudioStreamPlayer
var _audio_player_tts: AudioStreamPlayer

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
	
	_audio_player_tts = AudioStreamPlayer.new()
	_audio_player_tts.stream = AudioStreamWAV.load_from_file("res://addons/@fumohouse/fumo_touhou/assets/tts/marisa.wav")
	_audio_player_tts.stream.data = _audio_player_tts.stream.data.slice(0,8192)
	_audio_player_tts.bus = &"UI"
	add_child(_audio_player_tts)

func playSample():
	_audio_player_tts.pitch_scale = self.value
	_audio_player_tts.play()

func button_pressed():
	playSample()
	recent_press = 1

func hover():
	_audio_player_hover.play()

func _value_changed(new_value: float) -> void:
	if recent_press != 1:
		playSample()
	recent_press = 0
