extends DebugMenu


var _build_format_string := "[img=32x32]res://assets/textures/logo_dark.png[/img]" + \
		" [b]Fumohouse[/b] %s[url=egg]%s[/url]%s"

var _egg: int

var _effects := [
	["", ""],
	["[rainbow freq=0.2 sat=1 val=1]", "[/rainbow]"],
	["[wave amp=50 freq=2]", "[/wave]"],
	["[tornado radius=8 freq=5]", "[/tornado]"],
	["[shake rate=20 level=10]", "[/shake]"],
]


func _init():
	menu_name = "debug_info"


func _ready():
	super._ready()

	add_entry("build")
	var contents := get_entry("build").contents
	contents.meta_clicked.connect(_on_meta_clicked)
	contents.meta_underlined = false

	_update_egg()

	var ver_info := Engine.get_version_info()

	add_entry("godot_ver")
	set_val("godot_ver", "[b]Godot[/b] %d.%d.%d.%s.%s [%s]" % [
		ver_info.major, ver_info.minor, ver_info.patch,
		ver_info.status, ver_info.build, ver_info.hash.substr(0, 9)
	])

	DebugMenus.set_default_menu(self)


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
