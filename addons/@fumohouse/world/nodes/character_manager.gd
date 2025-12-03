class_name CharacterManager
extends CharacterManagerBase
## Default character manager.

const _CHARACTER_SCENE := preload("res://addons/@fumohouse/fumo/fumo.tscn")
const _DEATH_TIMEOUT := 5.0
const _FALL_LIMIT := -128.0

var _local_character: Fumo

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

## Node containing [Spawnpoint]s that will be selected randomly for newly spawning
## characters.
@export var spawnpoints: Node3D


func _ready():
	fumo_appearances.current_changed.connect(
		func(appearance):
			# TODO: when changing to Shanghai from a bigger fumo camera moves down (doll size?)
			_spawn_character(
				appearance, _local_character.global_transform if _local_character else null
			)
			# TODO: load_appearance() attaches new parts instead of replacing them,
			# so you can get two or more fumos overlapping eachother
			# Working around it by setting it to null first didn't seem to work either
			# Using the transform property (above) worked well enough however
			#
			# This does complicate the design for a load_character() method here,
			# if a utility function load_character() is desired it may be worth defining its users,
			# if it's just here it may make sense to just use the code above
			# I'm not sure if it makes sense to expose load_appearance() with this quirk
			#if _local_character:
				#_local_character.appearance_manager.appearance = null
				#_local_character.appearance_manager.load_appearance()
				#_local_character.appearance_manager.appearance = appearance
				#_local_character.appearance_manager.load_appearance()
			#else:
				#_spawn_character(appearance, null)
	)


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


func _spawn_character(
	appearance: Appearance = fumo_appearances._current, char_transform: Variant = null
) -> Node3D:
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

	character.appearance_manager.appearance = appearance
	# Loaded on ready

	character.camera = camera

	if _local_character:
		_delete_character(false, null)
	_local_character = character

	add_child(character)
	# Add after ready
	character.state.add_processor(CharacterAreaHandlerProcessor.new())

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
