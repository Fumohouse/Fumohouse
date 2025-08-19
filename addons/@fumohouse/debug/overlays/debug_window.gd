class_name DebugWindow
extends Control
## A base debug overlay.

## The action that will toggle this overlay.
var action := &""

var _is_dragging := false
var _is_resizing := false
var _custom_size: Vector2

@onready var _top_bar: Control = %TopBar
@onready var _contents: Control = %Contents
@onready var _resize_handle: Control = %ResizeHandle
@onready var _close_button: Button = %CloseButton


func _ready():
	_custom_size = get_minimum_size()

	_top_bar.gui_input.connect(_on_top_bar_gui_input)
	_resize_handle.gui_input.connect(_on_resize_handle_gui_input)
	_close_button.pressed.connect(set_visible.bind(false))

	set_window_visible(false)


func _gui_input(event: InputEvent):
	var emb := event as InputEventMouseButton
	if emb and emb.pressed:
		move_to_front()


func _unhandled_input(event: InputEvent):
	if not action.is_empty() and event.is_action_pressed(action):
		set_window_visible(not visible)
		get_viewport().set_input_as_handled()


## Show or hide the contents.
func set_contents_visible(visible: bool):
	_contents.visible = visible
	_resize_handle.visible = visible


## Show or hide the window.
func set_window_visible(visible: bool):
	self.visible = visible
	set_process(visible)


func _on_top_bar_gui_input(event: InputEvent):
	var emb := event as InputEventMouseButton
	if emb:
		if emb.double_click:
			set_contents_visible(not _contents.visible)
			_update_layout(position, size)
		else:
			_is_dragging = emb.pressed

		_top_bar.accept_event()
		return

	var emm := event as InputEventMouseMotion
	if emm:
		if not _is_dragging:
			return

		_update_layout(position + emm.relative, size)
		_top_bar.accept_event()
		return


func _on_resize_handle_gui_input(event: InputEvent):
	var emb := event as InputEventMouseButton
	if emb:
		_is_resizing = emb.pressed
		_resize_handle.accept_event()
		return

	var emm := event as InputEventMouseMotion
	if emm:
		if not _is_resizing:
			return

		_update_layout(position, size + emm.relative)
		_resize_handle.accept_event()
		return


func _update_layout(new_position: Vector2, new_size: Vector2):
	var viewport_rect := get_viewport_rect()

	# Setting minimum size is no longer automatic after layout change
	if _contents.visible:
		size = new_size.clamp(get_minimum_size(), viewport_rect.size - position)
		_custom_size = size
	else:
		size = get_minimum_size()

	# Keep position within viewport
	position = new_position.clamp(
		Vector2.ZERO, Vector2(viewport_rect.size.x - size.x, viewport_rect.size.y - size.y)
	)
