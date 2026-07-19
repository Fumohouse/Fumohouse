class_name InputConfigManager
extends Node
## Autoload for adding input options to [ConfigManager].


func _enter_tree():
	var cm := ConfigManager.get_singleton()

	cm.add_opt(&"input/sens/camera/first_person", 0.3)
	cm.add_opt(&"input/sens/camera/third_person", 1.0)
	cm.add_opt(&"input/sens/camera/zoom", 1.0)
	add_action(&"camera_rotate", mb_event(MOUSE_BUTTON_RIGHT))
	add_action(&"camera_rotate_up", kb_event(KEY_UP))
	add_action(&"camera_rotate_up", jm_event(JOY_AXIS_RIGHT_Y, -1.0), true)
	add_action(&"camera_rotate_down", kb_event(KEY_DOWN))
	add_action(&"camera_rotate_down", jm_event(JOY_AXIS_RIGHT_Y, 1.0), true)
	add_action(&"camera_rotate_left", kb_event(KEY_LEFT))
	add_action(&"camera_rotate_left", jm_event(JOY_AXIS_RIGHT_X, -1.0), true)
	add_action(&"camera_rotate_right", kb_event(KEY_RIGHT))
	add_action(&"camera_rotate_right", jm_event(JOY_AXIS_RIGHT_X, 1.0), true)
	add_action(&"camera_zoom_in", mb_event(MOUSE_BUTTON_WHEEL_UP))
	add_action(&"camera_zoom_out", mb_event(MOUSE_BUTTON_WHEEL_DOWN))
	add_action(&"camera_perspective", kb_event(KEY_F5))
	add_action(&"camera_perspective", jb_event(JOY_BUTTON_RIGHT_STICK), true)

	add_action(&"move_forward", kb_event(KEY_W))
	add_action(&"move_forward", jm_event(JOY_AXIS_LEFT_Y, -1.0), true)
	add_action(&"move_backward", kb_event(KEY_S))
	add_action(&"move_backward", jm_event(JOY_AXIS_LEFT_Y, 1.0), true)
	add_action(&"move_left", kb_event(KEY_A))
	add_action(&"move_left", jm_event(JOY_AXIS_LEFT_X, -1.0), true)
	add_action(&"move_right", kb_event(KEY_D))
	add_action(&"move_right", jm_event(JOY_AXIS_LEFT_X, 1.0), true)
	add_action(&"move_jump", kb_event(KEY_SPACE))
	add_action(&"move_jump", jb_event(JOY_BUTTON_A), true)
	add_action(&"move_sit", kb_event(KEY_C))
	add_action(&"move_sit", jb_event(JOY_BUTTON_B), true)
	add_action(&"move_run", kb_event(KEY_SHIFT))
	add_action(&"move_run", jb_event(JOY_BUTTON_X), true)

	add_action(&"reset_character", kb_event(KEY_F5, false, true))

	add_action(&"menu_back", kb_event(KEY_ESCAPE))
	add_action(&"menu_back", jb_event(JOY_BUTTON_START), true)
	add_action(&"chat", kb_event(KEY_ENTER))
	add_action(&"player_list", kb_event(KEY_TAB, true))
	add_action(&"toggle_hud", kb_event(KEY_F1))
	add_action(&"screenshot", kb_event(KEY_F2))

	add_action(&"debug_1", kb_event(KEY_F1, false, true))
	add_action(&"debug_2", kb_event(KEY_F2, false, true))
	add_action(&"debug_3", kb_event(KEY_F3, false, true))
	add_action(&"debug_4", kb_event(KEY_F4, false, true))

	InputMap.action_add_event(&"ui_accept", jb_event(JOY_BUTTON_A))


## Add a new action that will be added to [InputMap] and registered as a
## [ConfigManager] option with key [code]input/action/<ACTION>/bind[/code].
func add_action(action: StringName, default: InputEvent, is_alt := false):
	if not is_alt:
		InputMap.add_action(action)
	var suffix := &"_alt" if is_alt else &""
	var key := &"input/action/%s/bind%s" % [action, suffix]
	var cm := ConfigManager.get_singleton()
	cm.add_opt(
		key,
		default,
		func(value: InputEvent):
			if is_alt:
				return

			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, value)

			if cm.has_opt(key + &"_alt"):
				InputMap.action_add_event(action, cm.get_opt(key + &"_alt")),
		false,
		[],
		&"InputEvent"
	)


## Construct a [InputEventKey] for [method add_action].
static func kb_event(
	key: Key, ctrl := false, shift := false, alt := false, meta := false
) -> InputEvent:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	ev.alt_pressed = alt
	ev.meta_pressed = meta
	return ev


## Construct a [InputEventMouseButton] for [method add_action].
static func mb_event(button: MouseButton) -> InputEvent:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	return ev


## Construct a [InputEventJoypadButton] for [method add_action].
static func jb_event(button: JoyButton) -> InputEvent:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	return ev


## Construct a [InputEventJoypadMotion] for [method add_action].
static func jm_event(axis: JoyAxis, direction: float) -> InputEvent:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = direction
	return ev
