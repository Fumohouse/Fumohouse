class_name MusicPlayer
extends AudioStreamPlayer
## Playlist-based music player.

## Emitted when the currently playing song changes.
signal song_changed(song: Song)

const BUS := "Music"

var current_song: Song :
	get:
		return _current_song

var _playlists: Dictionary[StringName, Playlist] = {}

var _current_song: Song
var _current_playlist := &""

var _playlist_position := 0
var _saved_positions: Dictionary[StringName, PlaylistPosition] = {}

var _volume := 0.0
var _tween: Tween


static func get_singleton() -> MusicPlayer:
	return Modules.get_singleton("MusicPlayer") as MusicPlayer


func _ready():
	bus = BUS
	_volume = volume_db
	finished.connect(func():
		advance_playlist(1))


## Switch to the given playlist ID.
func switch_playlist(playlist_id: StringName):
	if playlist_id == _current_playlist:
		return

	if not _current_playlist.is_empty():
		_save_playlist_state()

	if playlist_id.is_empty():
		_reset_clip()
		_current_playlist = &""
		return

	_continue_playlist(playlist_id)


## Advance the current playlist by the given number of [param steps].
func advance_playlist(steps: int):
	if steps == 0 or _current_playlist.is_empty():
		return

	var playlist := _playlists[_current_playlist]

	_playlist_position += steps

	if _playlist_position >= playlist.songs.size():
		_playlist_position -= playlist.songs.size()
	elif _playlist_position < 0:
		_playlist_position += playlist.songs.size()

	_play(playlist.songs[_playlist_position], false, false, 0.0)


## Prepare the given [param playlists] to be played.
func load_playlists(playlists: Array[Playlist]):
	switch_playlist(&"")

	_playlists = {}
	_saved_positions = {}

	for playlist in playlists:
		assert(not _playlists.has(playlist.id),
				"A playlist with id %s already exists." % playlist.id)

		_playlists[playlist.id] = playlist


func _reset_clip():
	stop()
	stream = null
	_current_song = null
	song_changed.emit(null)


func _play_immediate(song: Song, seek: float):
	var was_paused := stream_paused

	if _current_song and song.id == _current_song.id:
		play(seek)
		stream_paused = was_paused
		return

	_reset_clip()

	var new_stream := load(song.path) as AudioStream
	assert(new_stream, "Failed to load audio stream: %s" % new_stream)

	stream = new_stream
	play(seek)
	stream_paused = was_paused

	_current_song = song
	song_changed.emit(song)


func _play(song: Song, transition_out: bool, transition_in: bool, seek: float):
	if not transition_out:
		_play_immediate(song, seek)
		return

	const TRANSITION_DURATION := 0.5

	# Some funny business with tweens and yielding behavior
	if _tween:
		_tween.kill()

	var tween1 := create_tween()
	tween1.tween_property(self, "volume_db", -100, TRANSITION_DURATION)

	_tween = tween1

	await tween1.finished

	if transition_in:
		if _tween and tween1 != _tween:
			_tween.kill()

		var tween2 := create_tween()
		tween2.tween_property(self, "volume_db", _volume, TRANSITION_DURATION)

		_tween = tween2
	else:
		volume_db = _volume

	_play_immediate(song, seek)


func _save_playlist_state():
	if _current_playlist.is_empty():
		return

	var pos := PlaylistPosition.new()
	pos.position = _playlist_position
	pos.time = get_playback_position()
	_saved_positions[_current_playlist] = pos


func _continue_playlist(playlist_id: StringName):
	var pos := _saved_positions.get(playlist_id)
	var playlist := _playlists[playlist_id]

	_current_playlist = playlist_id

	if pos:
		_playlist_position = pos.position
		await _play(playlist.songs[_playlist_position], true, true, pos.time)
	else:
		_playlist_position = 0
		await _play(playlist.songs[0], true, false, 0)


class PlaylistPosition extends RefCounted:
	var position := 0
	var time := 0.0
