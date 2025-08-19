extends Control

const Marquee = preload("res://addons/@fumohouse/common/nodes/marquee.gd")

const PLAY_ICON := ""
const PAUSE_ICON := ""
const TRANSITION_DURATION := 0.35

var _was_paused := false
var _is_seeking := false

var _tween: Tween

@onready var _mp := MusicPlayer.get_singleton()

@onready var _marquee: Marquee = %Marquee
@onready var _play: Button = %Play
@onready var _prev: Button = %Previous
@onready var _next: Button = %Next
@onready var _seek_bar: HSlider = %SeekBar


func _ready():
	_play.pressed.connect(_on_play_pressed)
	_seek_bar.drag_started.connect(_on_seek_started)
	_seek_bar.drag_ended.connect(_on_seek_ended)

	_prev.pressed.connect(_on_prev_next.bind(-1))
	_next.pressed.connect(_on_prev_next.bind(1))

	_was_paused = _mp.stream_paused
	_update_paused()

	_update_song(_mp.current_song)
	_mp.song_changed.connect(_update_song)


func _process(_delta: float):
	if _mp.stream_paused != _was_paused:
		_update_paused()

	if _mp.stream:
		if not _is_seeking:
			_seek_bar.value = _mp.get_playback_position() / _mp.stream.get_length()
	else:
		_seek_bar.value = 0


func _on_play_pressed():
	_mp.stream_paused = not _mp.stream_paused
	_update_paused()


func _on_seek_started():
	_is_seeking = true


func _on_seek_ended(_changed: bool):
	if _mp.stream:
		# HACK: Seek does nothing when paused
		var paused := _mp.stream_paused
		_mp.stream_paused = false

		# math.min: prevent loop when seeking to 1
		_mp.seek(_mp.stream.get_length() * minf(_seek_bar.value, 0.999))

		_mp.stream_paused = paused
	else:
		_seek_bar.value = 0

	_is_seeking = false


func _on_prev_next(ofs: int):
	_mp.advance_playlist(ofs)


func _update_paused():
	var paused := _mp.stream_paused
	_play.text = PLAY_ICON if paused else PAUSE_ICON
	_was_paused = paused


func _update_song(song: Song):
	if song:
		var artist_name := (
			song.artist.name_romanized
			if song.artist.name_unicode.is_empty()
			else song.artist.name_unicode
		)

		var song_name := song.name_romanized if song.name_unicode.is_empty() else song.name_unicode

		_marquee.label.text = "%s - %s" % [artist_name, song_name]
		_marquee.reset_position()
	else:
		_marquee.label.text = "<no song playing>"
		_marquee.reset_position()


func nav_hide():
	scale = Vector2(0, 1)
	visible = false


func nav_transition(vis: bool):
	if _tween:
		_tween.kill()

	visible = true

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tween.tween_property(self, "scale", Vector2.ONE if vis else Vector2(0, 1), TRANSITION_DURATION)
	tween.parallel().tween_property(
		self, "modulate", Color.WHITE if vis else Color.TRANSPARENT, TRANSITION_DURATION
	)

	_tween = tween

	if not vis:
		await tween.finished
		visible = false
