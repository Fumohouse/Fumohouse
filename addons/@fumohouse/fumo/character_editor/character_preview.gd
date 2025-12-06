extends VBoxContainer


signal edit_pressed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	%EditButton.pressed.connect(edit_pressed.emit)
