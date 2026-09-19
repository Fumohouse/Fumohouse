extends Slider

const _SOUND_FONT: SoundFont = preload(
	"res://addons/@fumohouse/fumo_touhou/resources/tts/marisa.tres"
)

var _audio_player_press: AudioStreamPlayer
var _audio_player_hover: AudioStreamPlayer
var _sound_font_player: SoundFontPlayer

# Prevents trigger without user input
var _is_dragging := false


func _ready() -> void:
	_audio_player_press = AudioStreamPlayer.new()
	_audio_player_press.stream = load("res://addons/@fumohouse/common/assets/sounds/select.ogg")
	_audio_player_press.bus = &"UI"
	add_child(_audio_player_press)

	_audio_player_hover = AudioStreamPlayer.new()
	_audio_player_hover.stream = load("res://addons/@fumohouse/common/assets/sounds/hover.ogg")
	_audio_player_hover.bus = &"UI"
	add_child(_audio_player_hover)

	_sound_font_player = SoundFontPlayer.new()
	_sound_font_player.font = _SOUND_FONT
	add_child(_sound_font_player)

	drag_started.connect(_on_drag_started)
	drag_ended.connect(_on_drag_ended)
	mouse_entered.connect(_audio_player_hover.play)


func _play_sample():
	_sound_font_player.play(
		&"a_la",
		func(player: AudioStreamPlayer):
			player.bus = &"UI"
			player.pitch_scale = value
	)


func _on_drag_started():
	_is_dragging = true


func _on_drag_ended(value_changed):
	_is_dragging = false


func _value_changed(new_value: float) -> void:
	# Heuristic for user input
	if (
		_is_dragging
		or (get_viewport().gui_get_focus_owner() == self and Input.is_anything_pressed())
	):
		_play_sample()
