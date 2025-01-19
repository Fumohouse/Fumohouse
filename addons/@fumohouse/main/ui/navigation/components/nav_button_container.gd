extends VBoxContainer

const NavButton := preload("nav_button.gd")
const MenuUtils := preload("../menu_utils.gd")

var _tween: Tween
var _button_idx := -1


func _ready():
	for button: NavButton in get_children():
		button.pressed.connect(_on_button_pressed.bind(button))


func nav_hide():
	for button: NavButton in get_children():
		button.disabled = true
		button.position.x = _button_target_x(false, button)
		button.modulate = Color.TRANSPARENT


func nav_show():
	for button: NavButton in get_children():
		button.disabled = false
		button.position.x = _button_target_x(true, button)
		button.modulate = Color.WHITE


func nav_transition(vis: bool):
	if _tween:
		_tween.kill()

	if vis:
		# Wait for container to update position before overriding it and animating.
		# Wait two frames since MessageQueue is flushed after the signal is fired (??).
		await get_tree().process_frame
		await get_tree().process_frame
		nav_hide()

	var tween := MenuUtils.common_tween(self, vis)
	var target_modulate := Color.WHITE if vis else Color.TRANSPARENT

	for i in range(get_child_count()):
		var button: NavButton = get_child(i)
		button.disabled = not vis

		var mod_tweener: PropertyTweener = \
				tween.parallel().tween_property(button, "modulate",
				target_modulate, MenuUtils.TRANSITION_DURATION)

		if i == _button_idx and not vis:
			mod_tweener.set_delay(0.1)
			continue

		var pos_tweener: PropertyTweener = \
				tween.parallel().tween_property(button, "position:x",
				_button_target_x(vis, button), MenuUtils.TRANSITION_DURATION)

		if _button_idx == -1 or vis:
			mod_tweener.set_delay(0.03 * i)

	_button_idx = -1


func _button_target_x(vis: bool, button: NavButton):
	return 0 if vis else -button.orig_width - MenuUtils.MARGIN


func _on_button_pressed(button: NavButton):
	_button_idx = button.get_index()
