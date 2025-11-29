extends "./config_bound_control.gd"
## A [Range] bound to [ConfigManager].

## Whether the option should only be updated when the mouse is released.
@export var on_release := false

var _is_dragging := false

@onready var _range := input as Range


func _ready():
	super()
	if on_release:
		var slider := _range as Slider
		slider.drag_started.connect(_on_drag_started)
		slider.drag_ended.connect(_on_drag_ended)
	else:
		_range.value_changed.connect(_on_value_changed)


func _set_value(value: Variant):
	_range.value = value


func _get_value():
	return _range.value


func _on_value_changed(value: float):
	update_config_value()


func _on_drag_started():
	_is_dragging = true


func _on_drag_ended(value_changed: bool):
	_is_dragging = false

	if value_changed:
		update_config_value()
