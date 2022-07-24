class_name DebugMenu
extends PanelContainer


@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var _debug_text: PackedScene = preload("debug_text.tscn")

var _entries := {}
var menu_name: StringName = ""
var action: StringName = ""


class DebugMenuEntry:
	var label: RichTextLabel
	var contents: RichTextLabel


func _ready():
	set_visible(false)
	if menu_name != "":
		DebugMenus.register_menu(self)


func _exit_tree():
	if menu_name != "":
		DebugMenus.deregister_menu(menu_name)


func add_entry(id: StringName, label: String = ""):
	var entry := DebugMenuEntry.new()

	if label == "":
		var debug_text: RichTextLabel = _debug_text.instantiate()
		vbox.add_child(debug_text)

		entry.contents = debug_text
	else:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var label_text: RichTextLabel = _debug_text.instantiate()
		label_text.text = "[b]" + label + "[/b]"
		hbox.add_child(label_text)

		var debug_text: RichTextLabel = _debug_text.instantiate()
		hbox.add_child(debug_text)

		vbox.add_child(hbox)

		entry.label = label_text
		entry.contents = debug_text

	_entries[id] = entry


func get_entry(id: StringName) -> DebugMenuEntry:
	return _entries[id]


func set_val(id: StringName, contents: String):
	_entries[id].contents.text = contents


func set_visible(is_vis: bool):
	visible = is_vis
	set_process(is_vis)
