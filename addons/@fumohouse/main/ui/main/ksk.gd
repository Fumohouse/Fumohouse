extends Button

const TRANSITION_DURATION := 0.3

var _tween: Tween

@onready var _logo: ColorRect = $Logo
@onready var _logo_mat: ShaderMaterial = _logo.material


func _ready():
	_logo.mouse_entered.connect(_on_mouse_entered)
	_logo.mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)


func _begin_tween():
	return create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _on_mouse_entered():
	if _tween:
		_tween.kill()

	_tween = _begin_tween()
	_tween.tween_property(_logo_mat, "shader_parameter/progress", 1.0,
			TRANSITION_DURATION)


func _on_mouse_exited():
	if _tween:
		_tween.kill()

	_tween = _begin_tween()
	_tween.tween_property(_logo_mat, "shader_parameter/progress", 0.0,
			TRANSITION_DURATION)


func _on_pressed():
	OS.shell_open("https://kyo.seki.pw/")
