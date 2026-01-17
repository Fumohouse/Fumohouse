class_name CharacterManager
extends CharacterManagerBase
## Default character manager.

const CharacterSpawn := preload("../packets/character_spawn.gd")
const CharacterDelete := preload("../packets/character_delete.gd")
const CharacterSync := preload("../packets/character_sync.gd")
const CharacterAppearance := preload("../packets/character_appearance.gd")

const _CHARACTER_SCENE := preload("res://addons/@fumohouse/fumo/fumo.tscn")
const _DEATH_TIMEOUT := 5.0
const _FALL_LIMIT := -128.0

## Node containing [Spawnpoint]s that will be selected randomly for newly spawning
## characters.
@export var spawnpoints: Node3D

var _characters: Dictionary[int, Fumo] = {}

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()
@onready var _nm := NetworkManager.get_singleton()


func _ready():
	_nm.client_joined.connect(_on_client_joined)
	_nm.client_peer_disconnected.connect(_on_peer_disconnected)

	_nm.server_peer_joined.connect(_on_server_peer_joined)
	_nm.server_peer_disconnected.connect(_on_peer_disconnected)

	_fumo_appearances.active_changed.connect(_on_active_appearance_changed)


func _process(delta: float):
	var local_char: Fumo = _get_character(0)
	# Respawn request handling
	if (
		local_char
		and CommonUtils.do_game_input(self)
		and Input.is_action_just_pressed("reset_character")
	):
		if _nm.is_active:
			var delete := CharacterDelete.new()
			delete.died = true
			_nm.send_packet(1, delete)

			get_tree().create_timer(_DEATH_TIMEOUT + 1.0).timeout.connect(
				func():
					var spawn := CharacterSpawn.new()
					spawn.appearance = _fumo_appearances.active
					_nm.send_packet(1, spawn),
				CONNECT_ONE_SHOT
			)
		else:
			_delete_character(0, true, func(): _spawn_character(0))

	# Fall limit handling
	if _nm.is_active:
		if not _nm.is_server:
			pass

		for peer in _characters:
			if _characters[peer].global_position.y >= _FALL_LIMIT:
				continue

			var appearance: Appearance = _characters[peer].appearance_manager.appearance
			_delete_character(peer, true, func(): _spawn_character(peer, appearance))
	elif local_char and local_char.global_position.y < _FALL_LIMIT:
		_delete_character(0, true, func(): _spawn_character(0))


func _load_appearance(peer: int, appearance: Appearance):
	var fumo: Fumo = _get_character(peer)
	if not fumo:
		return

	fumo.appearance_manager.appearance = appearance
	fumo.appearance_manager.load_appearance()

	if _nm.is_active and _nm.is_server:
		var chr_appearance := CharacterAppearance.new()
		chr_appearance.peer = peer
		chr_appearance.appearance = appearance
		_nm.send_packet(0, chr_appearance)


func _spawn_character(
	peer: int, appearance: Appearance = null, char_transform: Variant = null
) -> Node3D:
	peer = _get_real_id(peer)
	var fumo: Fumo = _CHARACTER_SCENE.instantiate()
	if _nm.is_active:
		if _nm.is_server:
			fumo.multiplayer_mode = CharacterMotionState.MultiplayerMode.MULTIPLAYER_SERVER
		elif peer == 0:
			fumo.multiplayer_mode = CharacterMotionState.MultiplayerMode.MULTIPLAYER_LOCAL
		else:
			fumo.multiplayer_mode = CharacterMotionState.MultiplayerMode.MULTIPLAYER_REMOTE
	else:
		fumo.multiplayer_mode = CharacterMotionState.MultiplayerMode.SINGLEPLAYER

	if not appearance:
		if peer == 0:
			appearance = _fumo_appearances.active
		else:
			return null

	if char_transform == null:
		if spawnpoints.get_child_count() == 0:
			fumo.global_transform = Transform3D.IDENTITY
		else:
			var spawnpoint: Spawnpoint = spawnpoints.get_child(
				randi() % spawnpoints.get_child_count()
			)
			fumo.global_transform = spawnpoint.get_spawn_point()
	else:
		fumo.global_transform = char_transform

	fumo.appearance_manager.appearance = appearance
	# Loaded on ready

	if _nm.is_active:
		fumo.name = _nm.local_identity if peer == 0 else _nm.get_peer_identity(peer)

	if peer in _characters:
		_characters[peer].queue_free()
	_characters[peer] = fumo

	add_child(fumo)
	if peer == 0:
		fumo.camera = camera
		debug_character.character = fumo
		# Add after ready
		fumo.state.add_processor(CharacterAreaHandlerProcessor.new())

	if _nm.is_active and _nm.is_server:
		var spawn := CharacterSpawn.new()
		spawn.peer = peer
		spawn.transform = fumo.global_transform
		spawn.appearance = appearance
		_nm.send_packet(0, spawn)

	return fumo


func _delete_character(peer: int, died: bool, callback := Callable()):
	var fumo: Fumo = _get_character(peer)
	if not fumo:
		return

	if died:
		if fumo.state.is_dead():
			return

		fumo.state.die(
			_DEATH_TIMEOUT,
			func():
				if callback.is_valid():
					callback.call()

				var real_id: int = _get_real_id(peer)
				# In case the character respawned during the wait or callback
				if real_id in _characters and _characters[real_id] == fumo:
					_characters.erase(real_id)
		)
	else:
		fumo.queue_free()
		_characters.erase(_get_real_id(peer))

	if _nm.is_active and _nm.is_server:
		var delete := CharacterDelete.new()
		delete.peer = peer
		delete.died = died
		_nm.send_packet(0, delete)


func _sync_characters(state: Dictionary[int, CharacterState]):
	for remote_peer in state:
		var char_state: CharacterState = state[remote_peer]
		_spawn_character(remote_peer, char_state.appearance, char_state.transform)
		# TODO: other state


func _get_real_id(peer: int):
	return 0 if _nm.is_active and peer == _nm.local_peer_id else peer


func _get_character(peer: int) -> Fumo:
	return _characters.get(_get_real_id(peer))


func _on_client_joined():
	# Request character on spawn
	var spawn := CharacterSpawn.new()
	spawn.appearance = _fumo_appearances.active
	_nm.send_packet(1, spawn)


func _on_server_peer_joined(peer: int):
	# Send current character state
	var state: Dictionary[int, CharacterState] = {}

	for remote_peer in _characters:
		if remote_peer == peer:
			continue

		var fumo: Fumo = _characters[remote_peer]

		var char_state := CharacterState.new()
		char_state.appearance = fumo.appearance_manager.appearance
		char_state.transform = fumo.global_transform
		# TODO: other state

		state[remote_peer] = char_state

	var sync := CharacterSync.new()
	sync.state = state
	_nm.send_packet(peer, sync)


func _on_peer_disconnected(peer: int):
	var fumo: Fumo = _get_character(peer)
	if not fumo:
		return
	fumo.queue_free()
	_characters.erase(_get_real_id(peer))


func _on_active_appearance_changed():
	if _nm.is_active:
		if _nm.is_server:
			return

		var chr_appearance := CharacterAppearance.new()
		chr_appearance.appearance = _fumo_appearances.active
		_nm.send_packet(1, chr_appearance)
	else:
		_load_appearance(0, _fumo_appearances.active)
