extends "./config_bound_control.gd"
## A special [Button] used to change keybinds for [InputConfigManager].

var event: InputEvent

@onready var _btn := input as Button


func _ready():
	super._ready()
	_on_toggled(_btn.button_pressed)
	_btn.toggled.connect(_on_toggled)


func _input(event: InputEvent):
	if not _btn.button_pressed or event.is_pressed():
		return

	var handle_event := false

	if event is InputEventKey:
		handle_event = true
	elif event is InputEventMouseButton:
		var emb := event as InputEventMouseButton
		if (
			emb.button_index == MOUSE_BUTTON_LEFT
			and Rect2(Vector2.ZERO, _btn.size).has_point(_btn.get_local_mouse_position())
		):
			return

		handle_event = true

	if handle_event:
		self.event = event
		update_config_value()
		get_viewport().set_input_as_handled()
		_btn.button_pressed = false


func _set_value(value: Variant):
	event = value
	_btn.text = _display_event(event)


func _get_value():
	return event


func _approx_equal(a: Variant, b: Variant):
	var eka := a as InputEventKey
	var ekb := b as InputEventKey
	if eka and ekb:
		# Defaults are always physical keycodes so this is ok
		return (
			eka.physical_keycode == ekb.physical_keycode
			and eka.get_modifiers_mask() == ekb.get_modifiers_mask()
		)

	var emba := a as InputEventMouseButton
	var embb := b as InputEventMouseButton
	if emba and embb:
		return emba.button_index == embb.button_index

	return super._approx_equal(a, b)


func _on_toggled(is_pressed: bool):
	if is_pressed:
		_btn.text = "Waiting for input…"
	else:
		_btn.text = _display_event(event)

	# Prevent options menu from being dismissed due to pressing menu_back
	# Two frames because... yeah.
	for i in range(2):
		await get_tree().process_frame

	_btn.set_meta("block_dismiss", is_pressed)


func _display_event(event: InputEvent):
	if event is InputEventKey:
		var ek := event as InputEventKey

		var modifier_str := ""
		if ek.ctrl_pressed:
			modifier_str += "Ctrl + "
		if ek.shift_pressed:
			modifier_str += "Shift + "
		if ek.alt_pressed:
			modifier_str += "Alt + "
		if ek.meta_pressed:
			modifier_str += "Meta + "

		if ek.physical_keycode == 0:
			# Physical not supported?
			return modifier_str + OS.get_keycode_string(ek.keycode) + " (Layout specific)"

		var keycode: Key = DisplayServer.keyboard_get_keycode_from_physical(ek.physical_keycode)
		return modifier_str + OS.get_keycode_string(keycode)
	elif event is InputEventMouseButton:
		var emb := event as InputEventMouseButton
		return emb.as_text()

	return "???"
