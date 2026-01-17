class_name CharacterAreaHandlerProcessor
extends CharacterMotionProcessor
## Handles switching [MusicPlayer] playlists when moving between regions.

const ID := &"area_handler"


func _init():
	id = ID


func _process(delta: float, cancelled: bool):
	var mp := MusicPlayer.get_singleton()
	if cancelled:
		mp.switch_playlist(&"")
		return

	var current_world: WorldManifest = WorldManager.get_singleton().current_world
	if not current_world:
		return

	for area in ctx.area_intersections:
		if not area.has_meta(&"playlist"):
			continue

		var playlist = area.get_meta(&"playlist")
		if playlist == "":
			mp.switch_playlist(current_world.default_playlist)
		else:
			mp.switch_playlist(playlist)

		return

	mp.switch_playlist(current_world.default_playlist)
