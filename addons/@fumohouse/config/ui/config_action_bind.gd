extends "./config_bound_control.gd"
## A special [Button] used to change keybinds for [InputConfigManager].

var event: InputEvent
var event_alt: InputEvent

var _key_alt := &""

@onready var _btn: Button = %Button
@onready var _btn_alt: Button = %ButtonAlt


func _ready():
	super()

	_key_alt = key + &"_alt"
	if not config_manager.has_opt(_key_alt):
		_btn_alt.hide()
		_key_alt = &""

	_on_toggled(_btn.button_pressed, _btn)
	_on_toggled(_btn_alt.button_pressed, _btn_alt)
	_btn.toggled.connect(_on_toggled.bind(_btn))
	_btn_alt.toggled.connect(_on_toggled.bind(_btn_alt))


func _input(event: InputEvent):
	if not _btn.button_pressed and not _btn_alt.button_pressed:
		return

	var handle_event := false

	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed():
			get_viewport().set_input_as_handled()
			return
		handle_event = true
	elif event is InputEventMouseButton:
		var emb := event as InputEventMouseButton
		if (
			emb.button_index == MOUSE_BUTTON_LEFT
			and Rect2(Vector2.ZERO, _btn.size).has_point(_btn.get_local_mouse_position())
		):
			return
		if event.is_pressed():
			get_viewport().set_input_as_handled()
			return

		handle_event = true
	elif event is InputEventJoypadMotion:
		var ejm := event as InputEventJoypadMotion
		if absf(ejm.axis_value) > 0.8:
			ejm = ejm.duplicate()
			ejm.axis_value = signf(ejm.axis_value)
			handle_event = true

	if handle_event:
		if _btn.button_pressed:
			self.event = event
		elif _btn_alt.button_pressed:
			event_alt = event
		update_config_value()
		get_viewport().set_input_as_handled()
		_btn.button_pressed = false
		_btn_alt.button_pressed = false


func update_config_value():
	_updating_config = true
	config_manager.set_opt(key, event)
	if not _key_alt.is_empty():
		config_manager.set_opt(_key_alt, event_alt)
	_updating_config = false


func _update_from_config():
	var value: Variant = config_manager.get_opt(key)
	var value_alt: Variant = config_manager.get_opt(_key_alt) if not _key_alt.is_empty() else null

	if revert_button:
		revert_button.visible = (
			not _approx_equal(value, config_manager.get_default(key))
			or (
				not _key_alt.is_empty()
				and not _approx_equal(value_alt, config_manager.get_default(_key_alt))
			)
		)

	if not _updating_config:
		event = value
		event_alt = value_alt
		_btn.text = _display_event(event)
		_btn_alt.text = _display_event(event_alt)


func _on_config_value_changed(key: StringName):
	if key != self.key and key != _key_alt:
		return

	_update_from_config()


func _on_revert_button_pressed():
	config_manager.set_opt(key, config_manager.get_default(key))
	if not _key_alt.is_empty():
		config_manager.set_opt(_key_alt, config_manager.get_default(_key_alt))


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

	var ejba := a as InputEventJoypadButton
	var ejbb := b as InputEventJoypadButton
	if ejba and ejbb:
		return ejba.button_index == ejbb.button_index

	var ejma := a as InputEventJoypadMotion
	var ejmb := b as InputEventJoypadMotion
	if ejma and ejmb:
		return ejma.axis == ejmb.axis and signf(ejma.axis_value) == signf(ejmb.axis_value)

	return super(a, b)


func _on_toggled(is_pressed: bool, btn: Button):
	if is_pressed:
		btn.text = "Waiting for input…"
	else:
		btn.text = _display_event(event_alt if btn == _btn_alt else event)

	# Prevent options menu from being dismissed due to pressing menu_back
	# Two frames because... yeah.
	for i in range(2):
		await get_tree().process_frame

	btn.set_meta("block_dismiss", is_pressed)


func _display_event(event: InputEvent):
	if not event:
		return "<null>"

	# keyboard_get_keycode_from_physical not supported
	if DisplayServer.get_name() == "headless":
		return "???"

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
	elif event is InputEventJoypadMotion:
		var sign := "-" if event.axis_value < 0 else "+"
		if event.axis == JOY_AXIS_LEFT_X:
			return "Left Stick X" + sign
		elif event.axis == JOY_AXIS_LEFT_Y:
			return "Left Stick Y" + sign
		elif event.axis == JOY_AXIS_RIGHT_X:
			return "Right Stick X" + sign
		elif event.axis == JOY_AXIS_RIGHT_Y:
			return "Right Stick Y" + sign
		else:
			return "???"
	else:
		return event.as_text()

	return "???"
