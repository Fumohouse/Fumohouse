class_name LineEditSound

extends LineEdit


#@export var audio_player: AudioStream

@export var _audio_player_submit: AudioStreamPlayer
@export var _audio_player_hover: AudioStreamPlayer
@export var _audio_player_changed: AudioStreamPlayer
@export var _audio_player_closed: AudioStreamPlayer

var edit_toggled: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_audio_player_submit = AudioStreamPlayer.new()
	_audio_player_submit.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/select.ogg")
	_audio_player_submit.bus = &"UI"
	text_submitted.connect(_text_submit)
	add_child(_audio_player_submit)

	_audio_player_hover = AudioStreamPlayer.new()
	_audio_player_hover.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/hover.ogg")
	_audio_player_hover.bus = &"UI"
	mouse_entered.connect(_button_mouse_entered)
	add_child(_audio_player_hover)

	_audio_player_changed = AudioStreamPlayer.new()
	_audio_player_changed.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/type.ogg")
	_audio_player_changed.bus = &"UI"
	gui_input.connect(_pop)
	add_child(_audio_player_changed)
	
	_audio_player_closed = AudioStreamPlayer.new()
	_audio_player_closed.stream = AudioStreamOggVorbis.load_from_file("res://addons/@fumohouse/common/assets/sounds/pop.ogg")
	_audio_player_closed.bus = &"UI"
	editing_toggled.connect(_toggle)
	add_child(_audio_player_closed)

func _text_submit(text):
	_audio_player_submit.play()
	
func _button_mouse_entered():
	_audio_player_hover.play()
	
func _pop(text):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && !Input.CURSOR_DRAG:
		_audio_player_changed.play()
	
func _toggle(text):
	_audio_player_changed.play()
	edit_toggled = !edit_toggled

func _input(event: InputEvent) -> void:
	if edit_toggled == true && event is InputEventKey:
		if event.is_pressed():
			_audio_player_changed.play()
		#print(event)
