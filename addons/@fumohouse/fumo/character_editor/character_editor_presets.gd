extends VBoxContainer

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _grid: GridContainer = %Grid

@onready var _search_edit: LineEdit = %SearchEdit


func _ready():
	_update_presets()
	fumo_appearances.entries_updated.connect(_update_presets)

	_search_edit.text_changed.connect(_filter_presets)


func _update_presets():
	for preset in fumo_appearances.entries:
		_grid.add_child(CharacterEditorGridItem.new(preset))


func _filter_presets(query: String):
	for child in _grid.get_children():
		var preset := child as CharacterEditorGridItem
		if preset == null:
			push_warning("Unknown grid item: '%s'" % child.name)
			continue
		preset.visible = query.is_empty() or preset.text.containsn(query)
