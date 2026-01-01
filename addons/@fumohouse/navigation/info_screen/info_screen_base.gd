extends "../screen_base.gd"

const CopyrightStanza := preload("copyright_stanza.gd")
const _COPYRIGHT_STANZA_SCENE := preload("copyright_stanza.tscn")

## Module whose dependencies are used to display copyright information. Can be
## changed in [code]_ready[/code] (update deferred).
@export var entry_module := &"@fumohouse/main"

@onready var _copyright_container: Control = %CopyrightInfo
@onready var _info_popup: Popup = %InfoPopup
@onready var _info_title: Label = %InfoTitle
@onready var _info_body: RichTextLabel = %InfoBody


func _ready():
	super()
	_load_copyright.call_deferred()


func _add_section(label: String, stanzas: Array[CopyrightFile.CopyrightFiles]):
	var module_container := VBoxContainer.new()
	module_container.add_theme_constant_override(&"separation", 20)

	var module_lbl := Label.new()
	module_lbl.text = label
	module_lbl.label_settings = LabelSettings.new()
	module_lbl.label_settings.font_size = 20
	module_container.add_child(module_lbl)

	for stanza in stanzas:
		var stanza_ctl: CopyrightStanza = _COPYRIGHT_STANZA_SCENE.instantiate()
		stanza_ctl.stanza = stanza
		stanza_ctl.license_pressed.connect(_show_license.bind(stanza.license))
		module_container.add_child(stanza_ctl)

	_copyright_container.add_child(module_container)


func _load_copyright():
	var modules: Array[StringName] = Modules.walk_dependencies(entry_module)
	for module_name in modules:
		var module := Modules.get_module(module_name)
		if not module.copyright:
			continue

		_add_section(module_name, module.copyright.files)

	var engine_info: Array[Dictionary] = Engine.get_copyright_info()
	var engine_stanzas: Array[CopyrightFile.CopyrightFiles] = []
	for stanza in engine_info:
		for part: Dictionary in stanza["parts"]:
			var stanza_res := CopyrightFile.CopyrightFiles.new()
			stanza_res.comment = stanza["name"]
			stanza_res.files = part["files"]
			stanza_res.copyright = part["copyright"]
			stanza_res.license = part["license"]
			engine_stanzas.push_back(stanza_res)
	_add_section("Godot Engine", engine_stanzas)


func _get_license_text(license: StringName) -> String:
	var license_data: CopyrightFile.CopyrightLicense = CopyrightFile.licenses.get(license)
	if license_data:
		return license_data.text
	else:
		var engine_licenses: Dictionary = Engine.get_license_info()
		if license in engine_licenses:
			return engine_licenses[license]

	return ""


func _show_license(license: StringName):
	var licenses: PackedStringArray = []
	for x in license.split(" and "):
		licenses += x.split(" or ")

	var license_text := ""
	if licenses.size() == 1:
		license_text = _get_license_text(licenses[0])
		if license_text.is_empty():
			return
	else:
		for license_name in licenses:
			var curr_text := _get_license_text(license_name)
			if curr_text.is_empty():
				continue
			license_text += "[b]%s:[/b]\n\n%s\n\n" % [license_name, curr_text]

	_info_popup.size = Vector2i(850, 650)
	_info_title.text = "%s License Text" % license
	_info_body.text = "[code]%s[/code]" % license_text.rstrip("\n")
	_info_popup.show()
