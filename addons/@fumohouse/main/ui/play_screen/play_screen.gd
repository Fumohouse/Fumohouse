extends "res://addons/@fumohouse/navigation/screen_base.gd"

const WorldCard = preload("world_card.gd")
const _WORLD_CARD_SCENE = preload("world_card.tscn")

@onready var _world_list: Control = %WorldList


func _ready():
	_refresh()


func _refresh():
	var worlds: Array[WorldManifest] = WorldManager.get_singleton().get_worlds()
	worlds.sort_custom(
		func(a: WorldManifest, b: WorldManifest):
			return a.display_name.naturalnocasecmp_to(b.display_name) < 0
	)

	for world in worlds:
		var card: WorldCard = _WORLD_CARD_SCENE.instantiate()
		card.world = world

		_world_list.add_child(card)
