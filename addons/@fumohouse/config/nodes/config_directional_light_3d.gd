class_name ConfigDirectionalLight3D
extends Node
## A node that configures [DirectionalLight3D] using [GraphicsConfigManager].

## The light to configure.
@export var light: DirectionalLight3D

@onready var cm := ConfigManager.get_singleton()


func _ready():
	_apply_bias()
	cm.value_changed.connect(_on_config_value_changed)


func _on_config_value_changed(key: StringName):
	if key == &"graphics/shadows/quality":
		_apply_bias()


func _apply_bias():
	light.shadow_bias = (
		GraphicsConfigManager
		. SHADOW_QUALITY_OPTIONS[cm.get_opt(&"graphics/shadows/quality")]["directional_bias"]
	)
