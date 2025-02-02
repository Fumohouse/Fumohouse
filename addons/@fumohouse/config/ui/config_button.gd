extends "./config_bound_control.gd"
## A [Button] bound to [ConfigManager].

@onready var _btn := input as Button


func _ready():
	super._ready()
	_btn.toggled.connect(_on_toggled)


func _set_value(value: Variant):
	_btn.button_pressed = value


func _get_value():
	return _btn.button_pressed


func _on_toggled(pressed: bool):
	update_config_value()
