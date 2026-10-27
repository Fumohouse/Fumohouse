class_name MultiplayerConfigManager
extends Node
## Autoload for adding multiplayer options to [ConfigManager].

const LOG_SCOPE := "Config:Multiplayer"


func _enter_tree():
	var cm := ConfigManager.get_singleton()

	cm.add_opt(&"multiplayer/username", "Fumo")
	cm.add_opt(&"multiplayer/favorites", [] as Array[Dictionary])
