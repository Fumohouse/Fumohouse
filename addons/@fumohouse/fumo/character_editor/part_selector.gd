extends Control

const PartPreviewButton := preload("part_preview_button.gd")
const _BUTTON_SCENE := preload("part_preview_button.tscn")

@export var scope: PartData.Scope

var _multiple: bool = false
var _exclude: Array = []

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()
@onready var _part_database: FumoPartDatabase = FumoPartDatabase.get_singleton()

@onready var _grid: GridContainer = %Grid
@onready var _title: Label = %Title


func _ready():
	_title.text = PartData.SCOPE_NAMES[scope]
	_config_slot()

	for part in _part_database.parts.values():
		if part.scope != scope:
			continue

		var button: PartPreviewButton = _BUTTON_SCENE.instantiate()
		button.part = part
		button.pressed.connect(_set_part.bind(part))
		_grid.add_child(button)


func show_title(vis: bool):
	_title.visible = vis


func _config_slot():
	var params := PartData.SLOT_PARAMS.get(scope)

	if params:
		_multiple = params.get("multiple", _multiple)
		_exclude = params.get("exclude", _exclude)


func _set_part(part_data: PartData):
	for key in _fumo_appearances.staging.attached_parts.keys():
		var attached := _part_database.get_part(key)

		if (
			((attached.scope == part_data.scope and not _multiple) or _exclude.has(attached.scope))
			and attached.id != part_data.id
		):
			_fumo_appearances.staging.attached_parts.erase(attached.id)

	if not _fumo_appearances.staging.attached_parts.erase(part_data.id):
		_fumo_appearances.staging.attached_parts[part_data.id] = null

	_fumo_appearances.staging_changed.emit()
