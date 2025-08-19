class_name RadioButtonContainer
extends Control
## A [Control] that contains buttons that can be toggled on and off.

## Fired when the selected buttons change.
signal selection_changed

## Whether to allow an empty selection. [b]Undefined behavior if changed after
## instantiation.[/b]
@export var allow_none := false

## Whether to allow multiple selection. [b]Undefined behavior if changed after
## instantiation.[/b]
@export var multi_selection := false

## The currently selected button. Only valid if [member multi_selection] is
## [code]false[/code].
var selected_button: Button:
	set = _set_selection,
	get = _get_selection

## The currently selected buttons. When [member allow_none] is
## [code]true[/code], the array may be empty. When [member multi_selection] is
## [code]false[/code], the array can have at most 1 item.
@export var selected_buttons: Array[Button]:
	set = _set_multiple_selection,
	get = _get_multiple_selection

var _selected_buttons: Array[Button] = []


func _init():
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)


func _on_child_entered_tree(child: Node):
	var btn := child as Button
	if not btn:
		push_error("Non-button child is present in RadioButtonContainer.")
		return

	btn.toggle_mode = true
	btn.button_pressed = false
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	btn.pressed.connect(_on_button_pressed.bind(btn))


func _on_child_exiting_tree(child: Node):
	var btn := child as Button
	if not btn:
		return

	btn.pressed.disconnect(_on_button_pressed.bind(btn))

	if _selected_buttons.has(btn):
		_selected_buttons.erase(btn)
		selection_changed.emit()


func _set_selection(selection: Button):
	for button in _selected_buttons:
		button.button_pressed = false

	if selection:
		_selected_buttons = [selection]
		selection.button_pressed = true
	else:
		_selected_buttons.clear()

	selection_changed.emit()


func _get_selection():
	if multi_selection:
		push_error("Cannot get selection of a RadioButtonContainer that allows multi selection.")
		return

	return _selected_buttons[0] if not _selected_buttons.is_empty() else null


func _set_multiple_selection(buttons: Array[Button]):
	if not multi_selection and buttons.size() > 1:
		push_error("Cannot select multiple buttons when multi_selection is false.")
		return

	if not allow_none and buttons.is_empty():
		push_error("Cannot select no buttons when allow_none is false.")
		return

	for button in _selected_buttons:
		button.button_pressed = false

	for button in buttons:
		button.button_pressed = true

	_selected_buttons = buttons
	selection_changed.emit()


func _get_multiple_selection():
	return _selected_buttons


func _on_button_pressed(button: Button):
	if _selected_buttons.has(button):
		if _selected_buttons.size() == 1 and not allow_none:
			button.button_pressed = true
			return

		button.button_pressed = false
		_selected_buttons.erase(button)
		selection_changed.emit()
	else:
		if multi_selection:
			_selected_buttons.push_back(button)
		else:
			for sel in _selected_buttons:
				sel.button_pressed = false
			_selected_buttons = [button]

		button.button_pressed = true
		selection_changed.emit()
