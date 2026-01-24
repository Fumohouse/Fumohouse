class_name InputConfigManager
extends Node
## Autoload for adding input options to [ConfigManager].


func _enter_tree():
	var cm := ConfigManager.get_singleton()

	cm.add_opt(&"input/sens/camera/first_person", 0.3)
	cm.add_opt(&"input/sens/camera/third_person", 1.0)
	cm.add_opt(&"input/sens/camera/zoom", 1.0)
	add_action(&"camera_rotate", mb_event(MOUSE_BUTTON_RIGHT))
	add_action(&"camera_zoom_in", mb_event(MOUSE_BUTTON_WHEEL_UP))
	add_action(&"camera_zoom_out", mb_event(MOUSE_BUTTON_WHEEL_DOWN))

	add_action(&"move_forward", kb_event(KEY_W))
	add_action(&"move_backward", kb_event(KEY_S))
	add_action(&"move_left", kb_event(KEY_A))
	add_action(&"move_right", kb_event(KEY_D))
	add_action(&"move_jump", kb_event(KEY_SPACE))
	add_action(&"move_sit", kb_event(KEY_C))
	add_action(&"move_run", kb_event(KEY_SHIFT))

	add_action(&"reset_character", kb_event(KEY_F5, false, true))

	add_action(&"menu_back", kb_event(KEY_ESCAPE))

	add_action(&"debug_1", kb_event(KEY_F1))
	add_action(&"debug_2", kb_event(KEY_F2))
	add_action(&"debug_3", kb_event(KEY_F3))
	add_action(&"debug_4", kb_event(KEY_F4))


## Add a new action that will be added to [InputMap] and registered as a
## [ConfigManager] option with key [code]input/action/<ACTION>/bind[/code].
func add_action(action: StringName, default: InputEvent):
	InputMap.add_action(action)
	ConfigManager.get_singleton().add_opt(
		&"input/action/%s/bind" % action,
		default,
		func(value: InputEvent):
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, value),
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
