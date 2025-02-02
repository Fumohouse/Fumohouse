class_name ConfigCamera3D
extends Node
## A node that configures a [Camera3D] using [GraphicsConfigManager].

## The camera to configure.
@export var camera: Camera3D

@onready var cm := ConfigManager.get_singleton()


func _ready():
	_apply_fov()
	cm.value_changed.connect(_on_config_value_changed)


func _on_config_value_changed(key: StringName):
	if key == &"graphics/fov":
		_apply_fov()


func _apply_fov():
	camera.fov = cm.get_opt(&"graphics/fov")
