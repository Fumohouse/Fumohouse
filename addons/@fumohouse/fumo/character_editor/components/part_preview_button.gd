extends "preview_button.gd"

const CharacterViewport := preload("character_viewport.gd")

@export var part: PartData

var _appearance := Appearance.new()

@onready var _character_viewport: CharacterViewport = %CharacterViewport


func _ready():
	super()

	tooltip_text = part.display_name

	# _appearance must not be local. Otherwise, Godot will report memory leaks if still awaiting draw.
	_character_viewport.character.appearance_manager.appearance = _appearance
	_appearance.attached_parts[part.id] = part.default_config

	_character_viewport.camera_controller.do_input = false

	# Wait until the preview is visible before loading any assets.
	await draw

	_character_viewport.character.appearance_manager.load_appearance()
	_character_viewport.character.set_rig_alpha(0.0)
