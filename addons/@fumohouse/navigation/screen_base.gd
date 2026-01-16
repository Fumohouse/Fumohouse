extends "transition_element.gd"

@export var tabs: RadioButtonContainer
@export var tab_content: Control

var _current_tab: Control


func _ready():
	if tabs and tab_content:
		for child in tab_content.get_children():
			child.hide()

		tabs.selected_button = tabs.get_child(0) as Button
		_on_selection_changed()
		tabs.selection_changed.connect(_on_selection_changed)


func _on_selection_changed():
	if not tabs or not tab_content:
		return

	if _current_tab:
		_current_tab.hide()

	var tab := tabs.selected_button
	if not tab:
		_current_tab = null
		return

	var tab_contents := tab_content.get_child(tab.get_index())
	tab_contents.show()
	_current_tab = tab_contents
