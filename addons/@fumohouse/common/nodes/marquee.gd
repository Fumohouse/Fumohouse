extends Control
## A [Control] wrapping a [Label] that scrolls when it overflows.

## The scroll speed in pixels per second.
@export_range(0, 120, 1, "suffix:px/s") var scroll_speed := 60.0

## The time to wait before starting the scroll.
@export_range(0, 100, 0.1, "suffix:s") var delay := 2.0

## The [Label] to scroll.
@export var label: Label

var _current_delay := 0.0


func _ready():
	_current_delay = delay


## Reset the position of the marquee (e.g., when the text changes).
func reset_position():
	_current_delay = delay
	label.position.x = 0


func _process(delta: float):
	if _current_delay > 0.0:
		label.position.x = 0
		_current_delay = move_toward(_current_delay, 0.0, delta)
		return

	label.size = label.custom_minimum_size

	if label.size.x > size.x:
		var new_x := label.position.x - scroll_speed * delta
		if new_x <= -label.size.x:
			new_x = size.x

		label.position.x = new_x
	else:
		label.position.x = 0
