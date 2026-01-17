extends Node
## Handles incoming multiplayer character packets and passes them to
## [CharacterManagerBase]. Sending packets should be handled by concrete
## [CharacterManagerBase] implementations.

const CharacterSpawn := preload("../packets/character_spawn.gd")
const CharacterDelete := preload("../packets/character_delete.gd")
const CharacterSync := preload("../packets/character_sync.gd")
const CharacterAppearance := preload("../packets/character_appearance.gd")

var _client_did_sync := false

@onready var _nm := NetworkManager.get_singleton()
@onready var _nmr := NetworkManagerRegistry.get_singleton()
@onready var _wm := WorldManager.get_singleton()


func _ready():
	_nm.resetted.connect(_on_nm_reset)

	_nmr.register_packet(CharacterSpawn.ID, CharacterSpawn.new, CharacterSpawn.new)
	_nmr.register_packet(CharacterDelete.ID, CharacterDelete.new, CharacterDelete.new)
	_nmr.register_packet(CharacterSync.ID, CharacterSync.new)
	_nmr.register_packet(CharacterAppearance.ID, CharacterAppearance.new, CharacterAppearance.new)

	_nmr.register_packet_handler(
		CharacterSpawn.ID, _on_character_spawn_server, _on_character_spawn_client
	)
	_nmr.register_packet_handler(
		CharacterDelete.ID, _on_character_delete_server, _on_character_delete_client
	)
	_nmr.register_packet_handler(CharacterSync.ID, Callable(), _on_character_sync_client)
	_nmr.register_packet_handler(
		CharacterAppearance.ID, _on_character_appearance_server, _on_character_appearance_client
	)


func _on_nm_reset():
	_client_did_sync = false


func _on_character_spawn_server(peer: int, packet: CharacterSpawn):
	if not _wm.current_char_manager:
		return
	_wm.current_char_manager._spawn_character(peer, packet.appearance)


func _on_character_spawn_client(packet: CharacterSpawn):
	if not _client_did_sync or not _wm.current_char_manager:
		return
	_wm.current_char_manager._spawn_character(packet.peer, packet.appearance, packet.transform)


func _on_character_delete_server(peer: int, packet: CharacterDelete):
	if not _wm.current_char_manager:
		return
	_wm.current_char_manager._delete_character(peer, packet.died)


func _on_character_delete_client(packet: CharacterDelete):
	if not _client_did_sync or not _wm.current_char_manager:
		return
	_wm.current_char_manager._delete_character(packet.peer, packet.died)


func _on_character_sync_client(packet: CharacterSync):
	if not _wm.current_char_manager:
		return
	_wm.current_char_manager._sync_characters(packet.state)
	_client_did_sync = true


func _on_character_appearance_server(peer: int, packet: CharacterAppearance):
	if not _wm.current_char_manager:
		return
	_wm.current_char_manager._load_appearance(peer, packet.appearance)


func _on_character_appearance_client(packet: CharacterAppearance):
	if not _client_did_sync or not _wm.current_char_manager:
		return
	_wm.current_char_manager._load_appearance(packet.peer, packet.appearance)
