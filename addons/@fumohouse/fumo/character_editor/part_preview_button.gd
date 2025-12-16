class_name PartPreviewButton
extends Button

@export var part: PartData

@onready var character_viewport: CharacterViewport = %CharacterViewport
@onready var indicator: Panel = %Indicator

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()


func _ready():
	var appearance := Appearance.new()

	# FIXME: huh, set null defaults on appearance.config definition instead?
	appearance.config[&"eyebrows"] = null
	appearance.config[&"eyes"] = null
	appearance.config[&"mouth"] = null

	character_viewport.character.appearance_manager.appearance = appearance

	# FIXME: Assertion failed: color is a required key in the part configuration.
	# ...even though the same function picks a default, asset bug though?
	if part.id == "socks_1":
		return

	await draw

	appearance.attached_parts[part.id] = part.default_config
	character_viewport.character.appearance_manager.load_appearance()
	character_viewport.character.rig.visible = false

	update_indicator(_fumo_appearances.staging)
	_fumo_appearances.staging_changed.connect(update_indicator)


func update_indicator(appearance: Appearance):
	indicator.visible = appearance.attached_parts.has(part.id)
