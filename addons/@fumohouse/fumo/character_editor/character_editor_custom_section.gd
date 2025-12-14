class_name CharacterEditorCustomSection
extends MarginContainer

const BUTTON_SCENE := preload(
	"res://addons/@fumohouse/fumo/character_editor/part_preview_button.tscn"
)

@export var scope: String

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _grid: GridContainer = %Grid
@onready var _title: Label = %Title


func _ready():
	_title.text = scope


func add_part(part: PartData):
	var button: PartPreviewButton = BUTTON_SCENE.instantiate()
	button.part = part
	_grid.add_child(button)
	button.pressed.connect(_set_part.bind(part))


func show_title(vis: bool):
	_title.visible = vis


func update_indicators():
	for button: PartPreviewButton in _grid.get_children():
		button.indicator.visible = _fumo_appearances.staging.attached_parts.has(button.part.id)


func _set_part(part: PartData):
	_fumo_appearances.with_staging(
		func(staging: Appearance):
			for button: PartPreviewButton in _grid.get_children():
				if button.part.id == part.id:
					continue

				staging.attached_parts.erase(button.part.id)

			if not staging.attached_parts.erase(part.id):
				staging.attached_parts[part.id] = part.default_config
	)

	update_indicators()
