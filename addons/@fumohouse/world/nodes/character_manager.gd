class_name CharacterManager
extends CharacterManagerBase
## Default character manager.

const _CHARACTER_SCENE := preload("res://addons/@fumohouse/fumo/fumo.tscn")
const _DEATH_TIMEOUT := 5.0
const _FALL_LIMIT := -128.0

## Node containing [Spawnpoint]s that will be selected randomly for newly spawning
## characters.
@export var spawnpoints: Node3D

var _local_character: Fumo


func _process(delta: float):
	if (
		_local_character
		and CommonUtils.do_game_input(self)
		and Input.is_action_just_pressed("reset_character")
	):
		var appearance := _local_character.appearance_manager.appearance
		_delete_character(true, func(): _spawn_character(appearance, null))

	if _local_character and _local_character.global_position.y < _FALL_LIMIT:
		var appearance := _local_character.appearance_manager.appearance
		_delete_character(true, func(): _spawn_character(appearance, null))


func _spawn_character(appearance: Appearance, char_transform: Variant) -> Node3D:
	var character: Fumo = _CHARACTER_SCENE.instantiate()

	if char_transform == null:
		if spawnpoints.get_child_count() == 0:
			character.global_transform = Transform3D.IDENTITY
		else:
			var spawnpoint: Spawnpoint = spawnpoints.get_child(
				randi() % spawnpoints.get_child_count()
			)
			character.global_transform = spawnpoint.get_spawn_point()
	else:
		character.global_transform = char_transform

	if appearance:
		character.appearance_manager.appearance = appearance
		# Loaded on ready

	character.camera = camera

	if _local_character:
		_delete_character(false, null)
	_local_character = character

	add_child(character)
	debug_character.character = character

	return character


func _delete_character(died: bool, callback: Variant):
	var character := _local_character
	if died:
		if character.state.is_dead():
			return

		character.state.die(
			_DEATH_TIMEOUT,
			func():
				if callback:
					callback.call()

				if character == _local_character:
					_local_character = null
		)
	else:
		character.queue_free()

		if character == _local_character:
			_local_character = null
