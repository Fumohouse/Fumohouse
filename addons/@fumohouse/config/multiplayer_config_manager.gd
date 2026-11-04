class_name MultiplayerConfigManager
extends Node
## Autoload for adding multiplayer options to [ConfigManager].

const LOG_SCOPE := "Config:Multiplayer"
const ServerManifest := preload("res://addons/@fumohouse/common/resource_types/server_manifest.gd")


func _enter_tree():
	var cm := ConfigManager.get_singleton()

	cm.add_opt(&"multiplayer/username", "Fumo")
	cm.add_opt(&"multiplayer/favorites", [] as Array[ServerManifest])

	var connect_default := ServerManifest.new()
	connect_default.name = ""
	cm.add_opt(&"multiplayer/quick_connect", connect_default)
