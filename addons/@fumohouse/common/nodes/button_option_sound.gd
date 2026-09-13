class_name OptionButtonSound

extends OptionButton

#@export var audio_player: AudioStream

@export var _audio_player_press: AudioStreamPlayer
@export var _audio_player_hover: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_audio_player_press = AudioStreamPlayer.new()
	_audio_player_press.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/select.ogg")
	_audio_player_press.bus = &"UI"
	pressed.connect(f_button_pressed)
	item_selected.connect(f_item_selected)
	add_child(_audio_player_press)

	_audio_player_hover = AudioStreamPlayer.new()
	_audio_player_hover.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/hover.ogg")
	_audio_player_hover.bus = &"UI"
	mouse_entered.connect(f_button_mouse_entered)
	#item_focused.connect(f_item_focused)
	add_child(_audio_player_hover)


func f_button_pressed():
	_audio_player_press.play()
	
func f_button_mouse_entered():
	_audio_player_hover.play()
	
func f_item_focused(index):
	pass
	
func f_item_selected(index):
	_audio_player_press.play()
