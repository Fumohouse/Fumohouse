@abstract class_name CharacterManagerBase
extends Node3D
## Base class for character managers.

## Camera to use for the local character.
@export var camera: CameraController
## Debug overlay to bind to the local character.
@export var debug_character: DebugCharacter


## Spawn a character with the given [param appearance] and
## [param char_transform] (either a [Transform3D] or [code]null[/code], where
## the default position or spawnpoint(s) should be used.
func _spawn_character(appearance: Appearance, char_transform: Variant) -> Node3D:
	return null


## Delete a character. If [param died] is [code]true[/code], kill the character
## (e.g., play the death animation). The given [param callback] (if not
## [code]null[/code]) is called after the character is killed.
func _delete_character(died: bool, callback: Variant):
	pass
