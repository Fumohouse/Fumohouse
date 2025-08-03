extends DebugWindow
## Platform information debug window.

const _EGG_OPEN := [
	"",
	"[rainbow freq=0.2 sat=1 val=1]",
	"[wave amp=50 freq=2]",
	"[tornado radius=8 freq=5]",
	"[shake rate=20 level=10]",
]

const _EGG_CLOSE := [
	"",
	"[/rainbow]",
	"[/wave]",
	"[/tornado]",
	"[/shake]",
]

const _DRIVERS := {
	"forward_plus": "Vulkan",
	"mobile": "Vulkan Mobile",
	"gl_compatibility": "GLES 3",
}

var _egg := 0

@onready var _tbl: DebugInfoTable = %DebugInfoTable


func _init():
	action = &"debug_1"


func _ready():
	super._ready()

	var build_contents := _tbl.add_entry(&"build").contents
	build_contents.meta_clicked.connect(_on_meta_clicked)
	build_contents.meta_underlined = false

	var ver_info: Dictionary = Engine.get_version_info()
	_tbl.add_entry(&"godot_ver")
	_tbl.set_val(&"godot_ver", "[b]Godot[/b] %d.%d.%d.%s.%s [%s]" % [
		ver_info["major"], ver_info["minor"], ver_info["patch"],
		ver_info["status"], ver_info["build"], ver_info["hash"].substr(0, 8),
	])

	_tbl.add_entry(&"os_name", "OS")
	_tbl.set_val(&"os_name", "%s (%s)" % [
		OS.get_name(),
		Engine.get_architecture_name(),
	])

	_tbl.add_entry(&"cpu", "CPU")
	_tbl.set_val(&"cpu", "%s (%d logical cores)" % [
		OS.get_processor_name(),
		OS.get_processor_count(),
	])

	_tbl.add_entry(&"gpu", "GPU")
	_tbl.set_val(&"gpu", "%s - %s - DeviceType: %d" % [
		RenderingServer.get_video_adapter_vendor(),
		RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_type(),
	])

	_tbl.add_entry(&"gpu_api", "API")
	_tbl.set_val(&"gpu_api", "%s %s" % [
		_DRIVERS[ProjectSettings.get_setting(&"rendering/renderer/rendering_method")],
		RenderingServer.get_video_adapter_api_version(),
	])

	var inspired_contents := _tbl.add_entry(&"inspired").contents
	inspired_contents.meta_clicked.connect(_on_meta_clicked)
	inspired_contents.text = "Debug menus inspired by [url=panku]Panku Console[/url]"

	_update_egg()


func _on_meta_clicked(meta: Variant):
	if meta == "egg":
		_egg = (_egg + 1) % _EGG_OPEN.size()
		_update_egg()
	elif meta == "panku":
		OS.shell_open("https://github.com/Ark2000/PankuConsole")


func _update_egg():
	_tbl.set_val(&"build", "[b]Fumohouse[/b] %s[url=egg]%s[/url]%s" % [
		_EGG_OPEN[_egg],
		DistConfig.get_build_string(),
		_EGG_CLOSE[_egg]
	])
