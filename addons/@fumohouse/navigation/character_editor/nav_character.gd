extends VBoxContainer

signal edit_pressed

const MenuUtils := preload("../menu_utils.gd")

var _tween: Tween

@onready var _edit_button: Button = %EditButton


func _ready():
	_edit_button.pressed.connect(edit_pressed.emit)


func nav_hide():
	scale = Vector2(0, 1)
	modulate = Color.TRANSPARENT


func nav_show():
	scale = Vector2.ONE
	modulate = Color.WHITE


func nav_transition(vis: bool):
	if _tween:
		_tween.kill()

	visible = true

	var tween := MenuUtils.common_tween(self, vis)

	tween.tween_property(
		self, "scale", Vector2.ONE if vis else Vector2(0, 1), MenuUtils.TRANSITION_DURATION
	)
	tween.parallel().tween_property(
		self, "modulate", Color.WHITE if vis else Color.TRANSPARENT, MenuUtils.TRANSITION_DURATION
	)

	_tween = tween

	if not vis:
		await tween.finished
		visible = false
