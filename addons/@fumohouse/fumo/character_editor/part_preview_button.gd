extends Button

const CharacterViewport := preload("character_viewport.gd")

@export var part: PartData

@onready var character_viewport: CharacterViewport = %CharacterViewport
@onready var indicator: Panel = %Indicator

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()


func _ready():
	var appearance := Appearance.new()
	character_viewport.character.appearance_manager.appearance = appearance

	# Wait until the preview is visible before loading any assets.
	await draw

	appearance.attached_parts[part.id] = part.default_config
	character_viewport.character.appearance_manager.load_appearance()
	character_viewport.character.set_rig_alpha(0.0)

	_update_indicator()
	_fumo_appearances.staging_changed.connect(_update_indicator)


func _update_indicator():
	indicator.visible = _fumo_appearances.staging.attached_parts.has(part.id)
