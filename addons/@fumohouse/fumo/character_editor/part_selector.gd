class_name CharacterEditorCustomSection
extends VBoxContainer

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
	button.pressed.connect(_set_part.bind(part))
	_grid.add_child(button)


func show_title(vis: bool):
	_title.visible = vis


func update_indicators():
	for button: PartPreviewButton in _grid.get_children():
		button.indicator.visible = _fumo_appearances.staging.attached_parts.has(button.part.id)


func _set_part(part_data: PartData):
	_fumo_appearances.with_staging(
		func(staging: Appearance):
			for button: PartPreviewButton in _grid.get_children():
				if button.part.id == part_data.id:
					continue

				staging.attached_parts.erase(button.part.id)

			if not staging.attached_parts.erase(part_data.id):
				var ap := AppearanceManager.AttachedPartInfo.new()
				ap.part_data = part_data
				staging.attached_parts[part_data.id] = ap
	)

	update_indicators()
