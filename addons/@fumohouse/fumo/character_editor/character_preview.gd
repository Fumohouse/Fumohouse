extends VBoxContainer

signal edit_pressed

@onready var _edit_button: Button = %EditButton


func _ready():
	_edit_button.pressed.connect(edit_pressed.emit)
