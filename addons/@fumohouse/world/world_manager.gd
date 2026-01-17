class_name WorldManager
extends Node
## Manages entering and leaving worlds.

## Fires when the world changes, or with [code]null[/code] when leaving a map.
signal world_changed(world: WorldManifest)

## Generic status update (for use with UI, etc.)
signal status_update(msg: String, failure: bool)

const _DEFAULT_WORLD := "@fumohouse/fumohouse"

## Callback to get the main scene when leaving. Should return a [Node].
var get_main_scene: Callable = func(): return null
## Callback to handle the main scene being added to the tree (e.g., to play
## animations). Takes in the node previously created by [member get_main_scene]
## and the previous scene. This function must free the previous scene (if any).
var prepare_main_scene: Callable = func(scene, prev_scene): pass

## The currently loaded world, or [code]null[/code] if no world is loaded.
var current_world: WorldManifest:
	get:
		return _current_world

## The current character manager, or [code]null[/code] if no world is loaded.
var current_char_manager: CharacterManagerBase:
	get:
		return _current_char_manager

var _runtime_scene: PackedScene

var _current_world: WorldManifest
var _current_runtime: WorldRuntime
var _current_char_manager: CharacterManagerBase

@onready var _nm := NetworkManager.get_singleton()


static func get_singleton() -> WorldManager:
	return Modules.get_singleton(&"WorldManager") as WorldManager


func _ready():
	# Avoid a cyclic dependency
	_runtime_scene = load("res://addons/@fumohouse/world/runtime.tscn")


## Get the list of currently detected worlds.
func get_worlds() -> Array[WorldManifest]:
	var worlds: Array[WorldManifest] = []

	for module in Modules.get_modules():
		if module is WorldManifest:
			worlds.push_back(module as WorldManifest)

	return worlds


## Load the given world into the scene tree.
func load_world(id: String) -> WorldManifest:
	var world: WorldManifest = null
	for check_world in get_worlds():
		if check_world.name == id:
			world = check_world
			break
	if not world:
		return null

	await _send_status_update("Loading world…")

	var scene = load(world.entry_scene) as PackedScene
	if not scene:
		push_error("Could not load scene at path %s." % [world.entry_scene])
		return null

	MusicPlayer.get_singleton().load_playlists(world.playlists)

	# Switch scenes manually (otherwise switch is deferred to next frame)
	var new_scene: Node = scene.instantiate()
	get_tree().root.add_child(new_scene)

	var runtime: WorldRuntime = _runtime_scene.instantiate()
	_current_world = world
	_current_runtime = runtime

	var char_manager: Node = new_scene.get_node_or_null("CharacterManager")
	if not char_manager or char_manager is not CharacterManagerBase:
		push_error("No character manager found.")
		return null

	char_manager.camera = runtime.camera
	char_manager.debug_character = runtime.debug_character
	_current_char_manager = char_manager

	new_scene.add_child(runtime)
	new_scene.move_child(runtime, 0)

	var curr_scene := get_tree().current_scene
	if curr_scene:
		curr_scene.queue_free()
	get_tree().current_scene = new_scene

	world_changed.emit(world)
	return world


## Start a singleplayer session using the given world.
func start_singleplayer(id: String):
	var world := await load_world(id)
	if not world:
		return

	_current_char_manager._spawn_character(0)


## Start a multiplayer server using the given world.
func start_multiplayer_server(id: String) -> Error:
	_nm.get_negotiation_payload = func(): return id.to_utf8_buffer()
	# TODO: server configuration
	var err := await _nm.serve(50103)
	if err != OK:
		return err
	var world := await load_world(id)
	if not world:
		return ERR_FILE_NOT_FOUND
	return OK


## Join a multiplayer server started by [method start_multiplayer_server].
## See [method NetworkManager.join].
func join_multiplayer_server(addr: String, port: int, identity: String, auth := "") -> Error:
	_nm.handle_negotiation_payload = _handle_negotiation_payload
	return await _nm.join(addr, port, identity, auth)


## Leave the current world.
func leave():
	if _nm.is_active:
		if _nm.is_server:
			_nm.close_server()
		else:
			_nm.disconnect_with_reason(1, "Disconnected")

	_current_world = null
	_current_runtime = null
	_current_char_manager = null

	await _send_status_update("Loading main scene…")

	var main_scene: Node = get_main_scene.call()
	get_tree().root.add_child(main_scene)

	var current_scene = get_tree().current_scene
	get_tree().current_scene = main_scene

	prepare_main_scene.call(main_scene, current_scene)

	play_title_playlist()


## Get the world that should be used for the title screen.
func get_title_world() -> WorldManifest:
	var worlds := get_worlds()

	for world in worlds:
		if world.name == _DEFAULT_WORLD:
			return world

	return worlds[0] if worlds.size() > 0 else null


## Play the title screen playlist.
func play_title_playlist():
	var title_world := get_title_world()
	MusicPlayer.get_singleton().load_playlists(title_world.playlists)
	MusicPlayer.get_singleton().switch_playlist(title_world.title_playlist)


func _send_status_update(msg: String, failure := false, ui_wait := true):
	status_update.emit(msg, failure)
	if ui_wait:
		await CommonUtils.wait_for_ui_update(self)


func _handle_negotiation_payload(payload: PackedByteArray):
	var world := await load_world(payload.get_string_from_utf8())
	if not world:
		_nm.disconnect_with_reason(1, "Client doesn't have requested map")
		return false

	return true
