extends VBoxContainer

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _grid: GridContainer = %Grid

@onready var _active_label: Label = %ActiveLabel

@onready var _search_edit: LineEdit = %SearchEdit


func _ready():
	_update_label(fumo_appearances._staging)
	fumo_appearances.staging_changed.connect(_update_label)
	%ApplyButton.pressed.connect(fumo_appearances.apply)
	_search_edit.text_changed.connect(_filter_presets)

	_update_presets()
	fumo_appearances.entries_updated.connect(_update_presets)


func _update_label(appearance: Appearance):
	_active_label.text = appearance.display_name


func _update_presets():
	for preset in fumo_appearances.entries:
		var item := CharacterEditorGridItem.new(preset)
		item.pressed.connect(_stage_appearance.bind(preset))
		_grid.add_child(item)


func _filter_presets(query: String):
	for child in _grid.get_children():
		var preset := child as CharacterEditorGridItem
		if preset == null:
			push_warning("Unknown grid item: '%s'" % child.name)
			continue
		preset.visible = query.is_empty() or preset.text.containsn(query)


func _stage_appearance(appearance: Appearance):
	fumo_appearances.with_staging(func(staging: Appearance): return appearance)
