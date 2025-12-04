extends VBoxContainer

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _grid: GridContainer = %Grid

@onready var _active_label: Label = %ActiveLabel

@onready var _item_template: Button = %FumoGridItem


func _ready():
	# TODO: remove
	_item_template.visible = false

	_update_label(fumo_appearances._staging)
	fumo_appearances.staging_changed.connect(_update_label)
	%ApplyButton.pressed.connect(fumo_appearances.apply)

	_update_presets()
	fumo_appearances.entries_updated.connect(_update_presets)


func _update_label(appearance: Appearance):
	_active_label.text = appearance.display_name

func _update_presets():
	for preset in fumo_appearances.entries:
		var item := _item_template.duplicate()
		item.text = preset.display_name
		item.visible = true
		item.pressed.connect(_stage_appearance.bind(preset))

		_grid.add_child(item)


func _stage_appearance(appearance: Appearance):
	fumo_appearances.with_staging(func(staging: Appearance): return appearance)
