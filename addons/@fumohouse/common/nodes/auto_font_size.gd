extends Control
## Script for automatically sizing the font on [Button]s, [Label]s, and similar
## UI elements according to their width.
## [url=https://forum.godotengine.org/t/is-there-auto-font-size-like-in-unity/41243/3]Source[/url]

## Theme variable corresponding to the current font.
@export var font_theme_var := &"font"
## Theme variable corresponding to the current font size.
@export var font_size_var := &"font_size"
## Property to watch for changes in the text.
@export var text_property := &"text"
## Property storing horizontal alignment.
@export var horizontal_alignment_property := &"horizontal_alignment"

## Minimum font size.
@export var min_size := 8
## Maximum font size.
@export var max_size := 20

## Horizontal padding of this UI element.
@export var padding := 16.0

var _base_font_size := 16


func _ready():
	_base_font_size = get_theme_font_size(font_size_var)

	for i in 2:
		# Wait for layout to settle (container, etc.)
		await get_tree().process_frame
	_update_font_size()


func _set(property: StringName, value: Variant) -> bool:
	if property == text_property:
		_update_font_size()

	return false


func _update_font_size():
	var font: Font = get_theme_font(font_theme_var)
	var font_size := _base_font_size

	var line := TextLine.new()
	line.alignment = get(horizontal_alignment_property)

	for i in max_size - min_size:
		line.clear()
		var created: bool = line.add_string(get(text_property), font, font_size)
		if created:
			var width: float = line.get_line_width()
			if width > size.x - padding:
				font_size -= 1
			elif width < size.x - padding:
				font_size += 1
			else:
				break

	add_theme_font_size_override(font_size_var, clampi(font_size, min_size, max_size))
