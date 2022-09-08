class_name DebugMenu
extends PanelContainer


@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer

var _entries := {}

var menu_name: StringName = ""
var action: StringName = ""
var menu_visible := false


class DebugMenuEntry:
	var root: Control
	var label: RichTextLabel
	var contents: RichTextLabel

	func set_visible(is_visible: bool):
		root.visible = is_visible


func _ready():
	update_visibility(menu_visible)

	# Should process after anything being observed
	process_priority = 100


func _unhandled_input(event: InputEvent):
	if action != "" and event.is_action_pressed(action):
		update_visibility(not menu_visible)


func _create_label() -> AutosizeRichText:
	var label := AutosizeRichText.new()
	label.bbcode_enabled = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.shortcut_keys_enabled = false

	label.clip_contents = false

	return label


func add_entry(id: StringName, label: String = "") -> DebugMenuEntry:
	var entry := DebugMenuEntry.new()

	if label == "":
		var debug_text := _create_label()
		vbox.add_child(debug_text)

		entry.root = debug_text
		entry.contents = debug_text
	else:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var label_text := _create_label()
		# TODO: This is probably an issue with theme propagation
		(func(): label_text.text = "[b]%s[/b]" % label).call_deferred()
		hbox.add_child(label_text)

		var debug_text := _create_label()
		hbox.add_child(debug_text)

		vbox.add_child(hbox)

		entry.root = hbox
		entry.label = label_text
		entry.contents = debug_text

	_entries[id] = entry
	return entry


func set_val(id: StringName, contents: String):
	_entries[id].contents.text = contents


func update_visibility(is_vis: bool):
	visible = is_vis
	set_process(is_vis)

	menu_visible = is_vis
