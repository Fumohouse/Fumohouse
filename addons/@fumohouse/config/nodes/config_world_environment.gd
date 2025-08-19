class_name ConfigWorldEnvironment
extends Node
## A node that configures a [WorldEnvironment] using [GraphicsConfigManager].

## The environment to configure.
@export var world_env: WorldEnvironment

@onready var cm := ConfigManager.get_singleton()


func _ready():
	_apply_ssr()
	_apply_ssao()
	_apply_ssil()
	_apply_sdfgi()
	_apply_glow()
	_apply_fog()

	_apply_brightness()
	_apply_saturation()
	_apply_contrast()

	cm.value_changed.connect(_on_config_value_changed)


func _on_config_value_changed(key: StringName):
	if key == &"graphics/ssr":
		_apply_ssr()
	elif key == &"graphics/ssao":
		_apply_ssao()
	elif key == &"graphics/ssil":
		_apply_ssil()
	elif key == &"graphics/sdfgi":
		_apply_sdfgi()
	elif key == &"graphics/glow":
		_apply_glow()
	elif key == &"graphics/volumetric_fog":
		_apply_fog()
	elif key == &"graphics/brightness":
		_apply_brightness()
	elif key == &"graphics/saturation":
		_apply_saturation()
	elif key == &"graphics/contrast":
		_apply_contrast()


func _apply_ssr():
	var opt: Dictionary = GraphicsConfigManager.SSR_OPTIONS[cm.get_opt(&"graphics/ssr")]

	world_env.environment.ssr_enabled = opt["enabled"]
	world_env.environment.ssr_max_steps = opt["steps"]


func _apply_ssao():
	var opt: Dictionary = GraphicsConfigManager.SSAO_OPTIONS[cm.get_opt(&"graphics/ssao")]

	world_env.environment.ssao_enabled = opt["enabled"]


func _apply_ssil():
	var opt: Dictionary = GraphicsConfigManager.SSIL_OPTIONS[cm.get_opt(&"graphics/ssil")]

	world_env.environment.ssil_enabled = opt["enabled"]


func _apply_sdfgi():
	var opt: Dictionary = GraphicsConfigManager.SDFGI_OPTIONS[cm.get_opt(&"graphics/sdfgi")]

	world_env.environment.sdfgi_enabled = opt["enabled"]


func _apply_glow():
	var opt: Dictionary = GraphicsConfigManager.GLOW_OPTIONS[cm.get_opt(&"graphics/glow")]

	world_env.environment.glow_enabled = opt["enabled"]


func _apply_fog():
	var opt: Dictionary = GraphicsConfigManager.VOLUMETRIC_FOG_OPTIONS[cm.get_opt(
		&"graphics/volumetric_fog"
	)]

	world_env.environment.volumetric_fog_enabled = opt["enabled"]


func _apply_brightness():
	world_env.environment.adjustment_brightness = cm.get_opt(&"graphics/brightness")


func _apply_saturation():
	world_env.environment.adjustment_saturation = cm.get_opt(&"graphics/saturation")


func _apply_contrast():
	world_env.environment.adjustment_contrast = cm.get_opt(&"graphics/contrast")
