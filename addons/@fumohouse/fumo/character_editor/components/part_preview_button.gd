extends "preview_button.gd"

const CharacterViewport := preload("character_viewport.gd")

@export var part: PartData

@onready var _character_viewport: CharacterViewport = %CharacterViewport


func _ready():
	super()

	tooltip_text = part.display_name

	var appearance := Appearance.new()
	_character_viewport.character.appearance_manager.appearance = appearance

	# Wait until the preview is visible before loading any assets.
	await draw

	appearance.attached_parts[part.id] = part.default_config
	_character_viewport.character.appearance_manager.load_appearance()
	_character_viewport.character.set_rig_alpha(0.0)
