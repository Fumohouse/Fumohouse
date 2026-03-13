extends Control

const FADE_OUT_AFTER := 3.0  # s
const FADE_OUT_DURATION := 2.0  # s

var _is_resizing := false
var _inactive_time := 0.0

@onready var _background: Control = %Background
@onready var _chat_box: LineEdit = %ChatBox
@onready var _chat_list: ScrollContainer = %ChatList
@onready var _resize_handle: Control = %ResizeHandle


func _ready():
	_resize_handle.gui_input.connect(_on_resize_handle_gui_input)
	_set_alpha(0)


func _process(delta: float):
	if get_global_rect().has_point(get_viewport().get_mouse_position()) or _chat_box.is_editing():
		_inactive_time = lerpf(_inactive_time, 0.0, CommonUtils.lerp_weight(delta, 1e-3))
	else:
		_inactive_time += delta

	if _inactive_time >= FADE_OUT_AFTER:
		_set_alpha(maxf(0.0, 1.0 - (_inactive_time - FADE_OUT_AFTER) / FADE_OUT_DURATION))
	else:
		_set_alpha(1.0)


func _set_alpha(alpha: float):
	_background.modulate.a = alpha
	_chat_box.modulate.a = alpha
	_chat_list.get_v_scroll_bar().modulate.a = alpha
	_resize_handle.modulate.a = alpha


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

		var viewport_rect := get_viewport_rect()
		size = (size + emm.relative).clamp(get_minimum_size(), viewport_rect.size - global_position)
		_resize_handle.accept_event()
		return
