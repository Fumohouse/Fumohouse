class_name AutosizeRichText
extends RichTextLabel


func _ready():
	finished.connect(_on_finished_loading)


func _on_finished_loading():
	custom_minimum_size = Vector2(
		get_content_width(),
		get_content_height()
	)
