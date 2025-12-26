extends Control

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _grid: GridContainer = %Grid
@onready var _search_edit: LineEdit = %SearchEdit


func _ready():
	_update_presets()
	_search_edit.text_changed.connect(_filter_presets)


func _stage_appearance(appearance: Appearance):
	_fumo_appearances.staging = appearance.duplicate(true)
	_fumo_appearances.staging_changed.emit()


func _update_presets():
	for appearance in _fumo_appearances.presets:
		var button := Button.new()
		button.text = appearance.display_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_stage_appearance.bind(appearance))
		_grid.add_child(button)


func _filter_presets(query: String):
	for button: Button in _grid.get_children():
		button.visible = query.is_empty() or button.text.containsn(query)
