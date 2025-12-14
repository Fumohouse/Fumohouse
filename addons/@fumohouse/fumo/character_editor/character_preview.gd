class_name CharacterPreview
extends VBoxContainer

signal edit_pressed

const TRANSITION_DURATION := 0.35

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

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tween.tween_property(self, "scale", Vector2.ONE if vis else Vector2(0, 1), TRANSITION_DURATION)
	tween.parallel().tween_property(
		self, "modulate", Color.WHITE if vis else Color.TRANSPARENT, TRANSITION_DURATION
	)

	_tween = tween

	if not vis:
		await tween.finished
		visible = false
