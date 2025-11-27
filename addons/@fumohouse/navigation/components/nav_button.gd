extends Button

const MenuUtils := preload("../menu_utils.gd")
const EXPAND := 20.0

var orig_width: float


func _ready():
	orig_width = size.x
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered():
	create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).tween_property(
		self, "size:x", orig_width + EXPAND, 0.2
	)


func _on_mouse_exited():
	create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).tween_property(
		self, "size:x", orig_width, 0.25
	)


func nav_hide():
	modulate = Color.TRANSPARENT
	position.x = _target_pos(false)


func nav_show():
	modulate = Color.WHITE
	position.x = _target_pos(true)


func nav_transition(vis: bool):
	var tween := MenuUtils.common_tween(self, vis)

	tween.tween_property(
		self, "modulate", Color.WHITE if vis else Color.TRANSPARENT, MenuUtils.TRANSITION_DURATION
	)

	tween.parallel().tween_property(
		self, "position:x", _target_pos(vis), MenuUtils.TRANSITION_DURATION
	)


func _target_pos(vis: bool):
	return 0.0 if vis else -size.x - MenuUtils.MARGIN
