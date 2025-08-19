class_name DebugInfoTable
extends VBoxContainer
## Table for displaying debug information.

var _entries: Dictionary[StringName, Entry] = {}


## Add an entry with ID [param id] and optionally, a [param label].
func add_entry(id: StringName, label := "") -> Entry:
	var entry := Entry.new()

	if label.is_empty():
		var contents_text := _create_label()
		add_child(contents_text)
		entry.root = contents_text
		entry.contents = contents_text
	else:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override(&"separation", 12)

		var label_text := _create_label()
		label_text.text = "[b]%s[/b]" % [label]
		hbox.add_child(label_text)

		var contents_text := _create_label()
		hbox.add_child(contents_text)

		add_child(hbox)

		entry.root = hbox
		entry.label = label_text
		entry.contents = contents_text

	_entries[id] = entry
	return entry


## Set the new contents of the entry with the given [param id].
func set_val(id: StringName, contents: String):
	_entries[id].contents.text = contents


func _create_label() -> RichTextLabel:
	var label := RichTextLabel.new()

	label.fit_content = true
	label.bbcode_enabled = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.shortcut_keys_enabled = false
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.clip_contents = false

	return label


class Entry:
	extends RefCounted
	var root: Control
	var label: RichTextLabel
	var contents: RichTextLabel
