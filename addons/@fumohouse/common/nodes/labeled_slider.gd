extends HBoxContainer
## A [HSlider] with a label indicating its value.

## The format string for the label.
## See https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
@export var format_string := "%.1f"

@onready var _slider: Slider = $Slider
@onready var _label: Label = $Label


func _ready():
	_on_value_changed(_slider.value)
	_slider.value_changed.connect(_on_value_changed)


func _on_value_changed(value: float):
	_label.text = format_string % value
