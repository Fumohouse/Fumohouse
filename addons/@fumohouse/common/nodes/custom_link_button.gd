class_name CustomLinkButton
extends ButtonSound
## A [Button] that opens a link and can have arbitrary content.

## The link.
@export var link := ""


func _ready():
	super()
	pressed.connect(_on_pressed)


func _on_pressed():
	if link.is_empty() or not link.begins_with("https://"):
		return

	OS.shell_open(link)
