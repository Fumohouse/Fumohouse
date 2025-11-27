extends Control

const MenuUtils := preload("menu_utils.gd")


func nav_hide():
	modulate = Color.TRANSPARENT


func nav_show():
	modulate = Color.WHITE


func nav_transition(vis: bool) -> Tween:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tween.tween_property(
		self, "modulate", Color.WHITE if vis else Color.TRANSPARENT, MenuUtils.TRANSITION_DURATION
	)

	return tween
