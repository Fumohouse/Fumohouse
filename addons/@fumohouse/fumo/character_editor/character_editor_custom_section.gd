class_name CharacterEditorCustomSection
extends MarginContainer

@export var scope: String

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _grid: GridContainer = %Grid

@onready var _title: Label = %Title


func _ready():
	_title.text = scope


func add_item(part: PartData):
	var button := Button.new()
	button.text = part.display_name
	button.pressed.connect(_set_part.bind(part))
	_grid.add_child(button)


func _set_part(part: PartData):
	fumo_appearances.with_staging(
		func(staging: Appearance):
			if not staging.attached_parts.erase(part.id):
				staging.attached_parts[part.id] = part
	)
