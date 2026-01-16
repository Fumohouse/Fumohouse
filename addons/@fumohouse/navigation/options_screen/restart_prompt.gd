extends "res://addons/@fumohouse/navigation/transition_element.gd"

@onready var config_manager := ConfigManager.get_singleton()
@onready var quit_manager := QuitManager.get_singleton()


func _ready():
	nav_hide()

	config_manager.restart_required.connect(func(): nav_transition(true))
	%Cancel.pressed.connect(func(): nav_transition(false))
	%Restart.pressed.connect(
		func():
			OS.set_restart_on_exit(true, OS.get_cmdline_args())
			quit_manager.quit()
	)


func nav_hide():
	hide()
	position.y = _target_y(false)


func nav_show():
	show()
	position.y = _target_y(true)


func nav_transition(vis: bool):
	show()

	var tween := MenuUtils.common_tween(self, vis)
	tween.tween_property(self, "position:y", _target_y(vis), MenuUtils.TRANSITION_DURATION)

	if not vis:
		await tween.finished
		hide()


func _target_y(vis: bool):
	if vis:
		return get_parent().size.y - size.y
	else:
		return get_parent().size.y + MenuUtils.MARGIN
