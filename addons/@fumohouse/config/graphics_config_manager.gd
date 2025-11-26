class_name GraphicsConfigManager
extends Node
## Autoload for adding graphics options to [ConfigManager].

const RENDERING_METHODS := ["forward_plus", "mobile", "gl_compatibility"]

# Graphics options and settings from https://github.com/godotengine/godot-demo-projects/blob/master/3d/graphics_settings/settings.gd
const SHADOW_QUALITY_OPTIONS: Array[Dictionary] = [
	{
		directional_size = 512,
		directional_bias = 0.06,
		positional_size = 0,
	},
	{
		directional_size = 1024,
		directional_bias = 0.04,
		positional_size = 1024,
	},
	{
		directional_size = 2048,
		directional_bias = 0.03,
		positional_size = 2048,
	},
	{
		directional_size = 4096,
		directional_bias = 0.02,
		positional_size = 4096,
	},
	{
		directional_size = 8192,
		directional_bias = 0.01,
		positional_size = 8192,
	},
	{
		directional_size = 16384,
		directional_bias = 0.005,
		positional_size = 16384,
	},
]

const SSR_OPTIONS: Array[Dictionary] = [
	{enabled = false, steps = 0},
	{enabled = true, steps = 8},
	{enabled = true, steps = 32},
	{enabled = true, steps = 56},
]

const SSAO_OPTIONS: Array[Dictionary] = [
	{
		enabled = false,
		quality = -1,
	},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSAO_QUALITY_VERY_LOW,
	},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSAO_QUALITY_LOW,
	},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
	},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSAO_QUALITY_HIGH,
	},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSAO_QUALITY_ULTRA,
	},
]

const SSIL_OPTIONS: Array[Dictionary] = [
	{enabled = false, quality = -1},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSIL_QUALITY_VERY_LOW,
	},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSIL_QUALITY_LOW,
	},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSIL_QUALITY_MEDIUM,
	},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSIL_QUALITY_HIGH,
	},
	{
		enabled = true,
		quality = RenderingServer.ENV_SSIL_QUALITY_ULTRA,
	},
]

const SDFGI_OPTIONS: Array[Dictionary] = [
	{enabled = false, half_res = false},
	{enabled = true, half_res = true},
	{enabled = true, half_res = false},
]

const GLOW_OPTIONS: Array[Dictionary] = [
	{enabled = false, upscale = false},
	{enabled = true, upscale = false},
	{enabled = true, upscale = true},
]

const VOLUMETRIC_FOG_OPTIONS: Array[Dictionary] = [
	{enabled = false, filter = false},
	{enabled = true, filter = false},
	{enabled = true, filter = true},
]

const LOD_THRESHOLD_SETTINGS := [8, 4, 2, 1, 0]

@onready var _viewport_start_size := Vector2i(
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height")
)


func _enter_tree():
	var cm := ConfigManager.get_singleton()

	# General
	cm.add_opt(
		&"graphics/rendering_method",
		0,
		func(value: int):
			cm.set_project_settings_opt(
				"rendering/renderer/rendering_method", RENDERING_METHODS[value]
			),
		true,
		["pc"]
	)

	cm.add_opt(
		&"graphics/window_mode",
		Window.MODE_WINDOWED,
		func(value: Window.Mode): get_tree().root.set_mode(value)
	)

	cm.add_opt(
		&"graphics/vsync_mode",
		DisplayServer.VSYNC_ENABLED,
		func(value: DisplayServer.VSyncMode): DisplayServer.window_set_vsync_mode(value)
	)

	cm.add_opt(
		&"graphics/ui_scale",
		1.0,
		func(value: float):
			get_tree().root.set_content_scale_size(Vector2i(_viewport_start_size * value))
	)

	cm.add_opt(&"graphics/fov", 75.0)

	# 3D Scaling
	cm.add_opt(
		&"graphics/scaling_3d/mode",
		Viewport.SCALING_3D_MODE_BILINEAR,
		func(value: Viewport.Scaling3DMode):
			if value == Viewport.SCALING_3D_MODE_FSR or value == Viewport.SCALING_3D_MODE_FSR2:
				cm.set_opt(
					&"graphics/scaling_3d/scale", minf(1, cm.get_opt(&"graphics/scaling_3d/scale"))
				)

			get_viewport().scaling_3d_mode = value
	)

	cm.add_opt(
		&"graphics/scaling_3d/fsr_sharpness",
		0.2,
		func(value: float): get_viewport().fsr_sharpness = value
	)

	cm.add_opt(
		&"graphics/scaling_3d/scale",
		1.0,
		func(value: float):
			if value > 1:
				cm.set_opt(&"graphics/scaling_3d/mode", Viewport.SCALING_3D_MODE_BILINEAR)

			get_viewport().scaling_3d_scale = value
	)

	# Anti Aliasing
	cm.add_opt(
		&"graphics/msaa3d",
		Viewport.MSAA_DISABLED,
		func(value: Viewport.MSAA): get_viewport().msaa_3d = value
	)

	cm.add_opt(&"graphics/taa", false, func(value: bool): get_viewport().use_taa = value)

	cm.add_opt(
		&"graphics/screen_space_aa",
		Viewport.SCREEN_SPACE_AA_DISABLED,
		func(value: Viewport.ScreenSpaceAA): get_viewport().screen_space_aa = value
	)

	# Quality
	cm.add_opt(
		&"graphics/shadows/quality",
		3,
		func(value: int):
			var opt := SHADOW_QUALITY_OPTIONS[value]
			RenderingServer.directional_shadow_atlas_set_size(opt["directional_size"], true)
			get_viewport().positional_shadow_atlas_size = opt["positional_size"]
	)

	cm.add_opt(
		&"graphics/shadows/filter",
		RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW,
		func(value: RenderingServer.ShadowQuality):
			RenderingServer.directional_soft_shadow_filter_set_quality(value)
			RenderingServer.positional_soft_shadow_filter_set_quality(value)
	)

	cm.add_opt(
		&"graphics/lod_threshold",
		3,
		func(value: int): get_viewport().mesh_lod_threshold = LOD_THRESHOLD_SETTINGS[value]
	)

	# Environment (ConfigWorldEnvironment)
	cm.add_opt(&"graphics/ssr", 0)

	cm.add_opt(
		&"graphics/ssao",
		0,
		func(value: int):
			var opt := SSAO_OPTIONS[value]
			if opt["enabled"]:
				RenderingServer.environment_set_ssao_quality(opt["quality"], true, 0.5, 2, 50, 300)
	)

	cm.add_opt(
		&"graphics/ssil",
		0,
		func(value: int):
			var opt := SSIL_OPTIONS[value]
			if opt["enabled"]:
				RenderingServer.environment_set_ssil_quality(opt["quality"], true, 0.5, 4, 50, 300)
	)

	cm.add_opt(
		&"graphics/sdfgi",
		0,
		func(value: int):
			var opt := SDFGI_OPTIONS[value]
			if opt["enabled"]:
				RenderingServer.gi_set_use_half_resolution(opt["half_res"])
	)

	cm.add_opt(
		&"graphics/glow",
		0,
		func(value: int):
			var opt := GLOW_OPTIONS[value]
			if opt["enabled"]:
				RenderingServer.environment_glow_set_use_bicubic_upscale(opt["upscale"])
	)

	cm.add_opt(
		&"graphics/volumetric_fog",
		0,
		func(value: int):
			var opt := VOLUMETRIC_FOG_OPTIONS[value]
			if opt["enabled"]:
				RenderingServer.environment_set_volumetric_fog_filter_active(opt["filter"])
	)

	# Adjustment
	cm.add_opt(&"graphics/brightness", 1.0)
	cm.add_opt(&"graphics/saturation", 1.0)
	cm.add_opt(&"graphics/contrast", 1.0)
