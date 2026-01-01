extends Control

var _updating := false

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()
@onready var _picker: ColorPickerButton = %EyeColorPicker


func _ready():
	_update_value()
	_fumo_appearances.staging_changed.connect(_update_value)

	_picker.color_changed.connect(_on_color_changed)


func _update_value():
	_updating = true
	_picker.color = _fumo_appearances.staging.config.get(&"eyes_color", Color.WHITE)
	_updating = false


func _on_color_changed(color: Color):
	if _updating:
		return

	_fumo_appearances.staging.config[&"eyes_color"] = _picker.color
	_fumo_appearances.staging_changed.emit()
