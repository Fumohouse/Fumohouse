@abstract class_name CharacterManagerBase
extends Node3D
## Base class for character managers.
##
## For the purpose of this class, a peer ID of [code]0[/code] should be
## interpreted as the local character.

## Camera to use for the local character.
@export var camera: CameraController
## Debug overlay to bind to the local character.
@export var debug_character: DebugCharacter


## Loads [param appearance] into the character of [param peer]. Does nothing
## if no such character is present.
func _load_appearance(peer: int, appearance: Appearance):
	pass


## Spawn a character for [param peer] with the given [param appearance] (or
## [code]null[/code] for the default), and [param char_transform] (either a
## [Transform3D] or [code]null[/code], where the default position or
## spawnpoint(s) should be used).
func _spawn_character(
	peer: int, appearance: Appearance = null, char_transform: Variant = null
) -> Node3D:
	return null


## Delete the character for [param peer]. If [param died] is [code]true[/code],
## kill the character (e.g., play the death animation). The given
## [param callback] (if not empty) is called after the character is killed.
func _delete_character(peer: int, died: bool, callback := Callable()):
	pass


## Sync characters with server state.
func _sync_characters(state: Dictionary[int, CharacterState]):
	pass


class CharacterState:
	extends RefCounted
	var appearance: Appearance
	var transform: Transform3D
	# TODO: include CharacterMotionState state
