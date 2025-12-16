extends VBoxContainer

const _BUTTON_SCENE := preload(
	"res://addons/@fumohouse/fumo/character_editor/part_preview_button.tscn"
)

@export var scope: PartData.Scope

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()
@onready var _part_database: FumoPartDatabase = FumoPartDatabase.get_singleton()

@onready var _grid: GridContainer = %Grid
@onready var _title: Label = %Title


func _ready():
	_title.text = PartData.Scope.keys()[scope]

	for part in _part_database.parts.values():
		if part.scope != scope:
			continue

		var button := _BUTTON_SCENE.instantiate()
		button.part = part
		button.pressed.connect(_set_part.bind(part))
		_grid.add_child(button)


func show_title(vis: bool):
	_title.visible = vis


func _set_part(part_data: PartData):
	for button in _grid.get_children():
		if button.part.id == part_data.id:
			continue

		_fumo_appearances.staging.attached_parts.erase(button.part.id)

	if not _fumo_appearances.staging.attached_parts.erase(part_data.id):
		_fumo_appearances.staging.attached_parts[part_data.id] = part_data.default_config

	_fumo_appearances.staging_emit()
