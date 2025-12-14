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
	_grid.add_child(button)
	button.pressed.connect(_set_part.bind(part))

	# FIXME: Assertion failed: color is a required key in the part configuration.
	# ...even though the same function picks a default, asset bug though?
	if part.id == "socks_1":
		return

	await button.draw

	var appearance := Appearance.new()
	appearance.attached_parts[part.id] = part.default_config
	# FIXME: huh, set null defaults on appearance.config definition instead?
	appearance.config[&"eyebrows"] = null
	appearance.config[&"eyes"] = null
	appearance.config[&"mouth"] = null

	button.character_viewport.character.appearance_manager.appearance = appearance
	button.character_viewport.character.appearance_manager.load_appearance()
	button.character_viewport.character.rig.visible = false


func show_title(vis: bool):
	_title.visible = vis


func _set_part(part: PartData):
	_fumo_appearances.with_staging(
		func(staging: Appearance):
			if not staging.attached_parts.erase(part.id):
				staging.attached_parts[part.id] = part.default_config
	)
