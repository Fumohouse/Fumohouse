extends Slider

var _audio_player_press: AudioStreamPlayer
var _audio_player_hover: AudioStreamPlayer
var _audio_player_tts: AudioStreamPlayer
var soundfont: SoundFont = load("res://addons/@fumohouse/fumo_touhou/resources/tts/marisa.tres")

# If this is set to 0 the slider will trigger sound on startup
var _recent_press := false

func _ready() -> void:
	_audio_player_press = AudioStreamPlayer.new()
	_audio_player_press.stream = load("res://addons/@fumohouse/common/assets/sounds/select.ogg")
	_audio_player_press.bus = &"UI"
	add_child(_audio_player_press)
	
	_audio_player_hover = AudioStreamPlayer.new()
	_audio_player_hover.stream = load("res://addons/@fumohouse/common/assets/sounds/hover.ogg")
	_audio_player_hover.bus = &"UI"
	add_child(_audio_player_hover)
	
	_audio_player_tts = AudioStreamPlayer.new()
	_audio_player_tts.bus = &"UI"
	add_child(_audio_player_tts)
	
	drag_started.connect(_on_drag_started)
	drag_ended.connect(_on_drag_ended)
	mouse_entered.connect(_audio_player_hover.play)


func _play_sample():
	_audio_player_tts.pitch_scale = value
	soundfont.play_menu(_audio_player_tts,&"a_la")


func _on_drag_started():
	_play_sample()
	_recent_press = true


func _on_drag_ended(value_changed):
	_recent_press = false


func _value_changed(new_value: float) -> void:
	_play_sample()
