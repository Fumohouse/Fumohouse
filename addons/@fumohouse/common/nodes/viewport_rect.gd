class_name ViewportRect
extends TextureRect
## A [TextureRect] displaying the contents of a [SubViewport].
##
## The [member viewport] is scaled according to the size of this node and of the
## in-game window, and relevant [InputEvent]s received by this node are passed
## on to it.

## Disables handling of input events.
@export var disable_input: bool = false
## The viewport to display on the texture.
@export var viewport: SubViewport


func _ready():
	texture = viewport.get_texture()

	_scale_viewport()
	get_window().size_changed.connect(_scale_viewport)
	resized.connect(_scale_viewport)


func _scale_viewport():
	var window := get_window()
	var scale := (window.size as Vector2) / (window.content_scale_size as Vector2)
	viewport.size = size * max(scale.x, scale.y)


func _gui_input(event: InputEvent):
	if disable_input:
		return

	var window := get_window()
	var scale := (window.size as Vector2) / (window.content_scale_size as Vector2)

	if event is InputEventMouse:
		event.position *= scale
	if event is InputEventMouseMotion:
		event.relative *= scale

	viewport.push_input(event, true)
	accept_event()
