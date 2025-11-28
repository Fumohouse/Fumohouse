class_name WorldManager
extends Node
## Manages entering and leaving worlds.


static func get_singleton() -> WorldManager:
	return Modules.get_singleton(&"WorldManager") as WorldManager
