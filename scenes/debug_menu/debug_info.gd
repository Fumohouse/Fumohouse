extends DebugMenu


var _build_format_string := "[img=32x32]res://assets/textures/logo_dark.png[/img]" + \
		" [b]Fumohouse[/b] %s[url=egg]%s[/url]%s"

var _egg: int

var _other_entries := []
var _other_visible := false

var _effects := [
	["", ""],
	["[rainbow freq=0.2 sat=1 val=1]", "[/rainbow]"],
	["[wave amp=50 freq=2]", "[/wave]"],
	["[tornado radius=8 freq=5]", "[/tornado]"],
	["[shake rate=20 level=10]", "[/shake]"],
]

var _drivers := {
	"forward_plus": "Vulkan",
	"mobile": "Vulkan Mobile",
	"gl_compatibility": "GLES 3",
}


func _init():
	menu_name = "debug_info"
	menu_visible = true


func _ready():
	super._ready()

	var contents: RichTextLabel = add_entry("build").contents
	contents.meta_clicked.connect(_on_meta_clicked)
	contents.meta_underlined = false

	_update_egg()

	var ver_info := Engine.get_version_info()

	add_entry("godot_ver")
	set_val("godot_ver", "[b]Godot[/b] %d.%d.%d.%s.%s [%s]" % [
		ver_info.major, ver_info.minor, ver_info.patch,
		ver_info.status, ver_info.build, ver_info.hash.substr(0, 9)
	])

	_add_other_entry("os_name", "OS")
	set_val("os_name", OS.get_name())

	_add_other_entry("cpu", "CPU")
	set_val("cpu", "%s (%d logical cores)" % [
		OS.get_processor_name(),
		OS.get_processor_count(),
	])

	_add_other_entry("gpu", "GPU")
	set_val("gpu", "%s - %s - DeviceType: %d" % [
		RenderingServer.get_video_adapter_vendor(),
		RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_type(),
	])

	_add_other_entry("gpu_api", "API")
	set_val("gpu_api", "%s %s" % [
		_drivers[ProjectSettings.get_setting("rendering/renderer/rendering_method")],
		RenderingServer.get_video_adapter_api_version(),
	])

	_set_other_visible(false)


func _add_other_entry(id: StringName, label: String = ""):
	_other_entries.append(add_entry(id, label))


func _set_other_visible(vis: bool):
	for item in _other_entries:
		item.set_visible(vis)

	_other_visible = vis


func _unhandled_input(event: InputEvent):
	super._unhandled_input(event)

	if event.is_action_pressed("debug_1"):
		_set_other_visible(not _other_visible)


func _update_egg():
	var effect = _effects[_egg]

	set_val("build", _build_format_string % [
		effect[0], Utils.get_build_string(), effect[1]
	])


func _on_meta_clicked(meta: Variant):
	if meta == "egg":
		_egg += 1
		_egg %= _effects.size()

		_update_egg()
