extends Control
## A [Control] wrapping a [Label] that scrolls when it overflows.

## The scroll speed in pixels per second.
@export_range(0, 120, 1, "suffix:px/s") var scroll_speed := 60.0

## The [Label] to scroll.
@export var label: Label


func _process(delta: float):
	label.size = label.custom_minimum_size

	if label.size.x > size.x:
		var new_x := label.position.x - scroll_speed * delta
		if new_x <= -label.size.x:
			new_x = size.x

		label.position.x = new_x
	else:
		label.position.x = 0
