extends Button

@onready var _indicator: Control = %Indicator


func _ready():
	_on_toggled(button_pressed)
	toggled.connect(_on_toggled)


func _on_toggled(on: bool):
	_indicator.visible = on
