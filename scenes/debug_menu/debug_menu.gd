class_name DebugMenu
extends PanelContainer


@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer

var _entries := {}
var menu_name: StringName = ""
var action: StringName = ""


class DebugMenuEntry:
	var label: RichTextLabel
	var contents: RichTextLabel


func _ready():
	update_visibility(false)

	# Should process after anything being observed
	process_priority = 100

	if menu_name != "":
		DebugMenus.register_menu(self)


func _exit_tree():
	if menu_name != "":
		DebugMenus.deregister_menu(menu_name)


func _create_label() -> AutosizeRichText:
	var label := AutosizeRichText.new()
	label.bbcode_enabled = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.shortcut_keys_enabled = false

	label.clip_contents = false

	return label


func add_entry(id: StringName, label: String = ""):
	var entry := DebugMenuEntry.new()

	if label == "":
		var debug_text := _create_label()
		vbox.add_child(debug_text)

		entry.contents = debug_text
	else:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var label_text := _create_label()
		label_text.text = "[b]%s[/b]" % label
		hbox.add_child(label_text)

		var debug_text := _create_label()
		hbox.add_child(debug_text)

		vbox.add_child(hbox)

		entry.label = label_text
		entry.contents = debug_text

	_entries[id] = entry


func get_entry(id: StringName) -> DebugMenuEntry:
	return _entries[id]


func set_val(id: StringName, contents: String):
	_entries[id].contents.text = contents


func update_visibility(is_vis: bool):
	visible = is_vis
	set_process(is_vis)
