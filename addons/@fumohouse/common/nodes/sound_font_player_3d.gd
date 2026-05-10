class_name SoundFontPlayer3D
extends Node3D
## A node that can play multiple [SoundFont] samples concurrently in 3D.

## The sound font to play.
@export var font: SoundFont

var _active: Dictionary[Node, bool] = {}


## Play the given [param sample], calling [param setup] (if given) with the
## chosen [AudioStreamPlayer3D]. Asynchronous function returns at the end of the
## sample.
func play(sample: StringName, setup := Callable()):
	var player: AudioStreamPlayer3D = _get_player()

	_active[player] = true
	if setup.is_valid():
		setup.call(player)
	await font.play_3d(player, sample)
	_active[player] = false


func _get_player() -> AudioStreamPlayer3D:
	for child: AudioStreamPlayer3D in get_children():
		if not _active.get(child, false):
			return child

	var player := AudioStreamPlayer3D.new()
	add_child(player)
	return player
