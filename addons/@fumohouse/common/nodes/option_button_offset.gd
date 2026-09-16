@tool
class_name OptionButtonOffset
extends OptionButton
## An [OptionButton] variant that allows adjusting the offset of its
## [PopupMenu].

## The space between the button and its menu.
@export var menu_spacing := 4


func _ready():
	pressed.connect(_on_pressed)


func _on_pressed():
	get_popup().position += Vector2i(0, menu_spacing)
