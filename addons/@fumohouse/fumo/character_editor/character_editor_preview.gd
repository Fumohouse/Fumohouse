extends VBoxContainer

const CharacterViewport := preload("components/character_viewport.gd")

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _character_name: LineEdit = %CharacterName
@onready var _character_viewport: CharacterViewport = %CharacterViewport
@onready var _apply_button: Button = %ApplyButton

@onready var _scale_slider: HSlider = %ScaleSlider
@onready var _scale_label: Label = %ScaleLabel
@onready var _scale_presets: Node = %ScalePresets


func _ready():
	_update()
	_fumo_appearances.staging_changed.connect(_update)

	_apply_button.pressed.connect(_fumo_appearances.apply)

	_character_name.text_changed.connect(_update_name)
	_scale_slider.value_changed.connect(_update_scale)

	for button: Button in _scale_presets.get_children():
		var scale: float = button.get_meta("scale_preset")
		if not scale:
			continue

		button.pressed.connect(_update_scale.bind(scale))


func _update():
	var appearance := _fumo_appearances.staging
	# Avoid cursor movement when setting same text
	if _character_name.text != appearance.display_name:
		_character_name.text = appearance.display_name

	var scale = appearance.config.get(&"scale")
	_scale_label.text = "%.f%%" % (scale * 100)
	# does not appear to cause a circular dependency as value_changed doesn't fire back to this
	_scale_slider.value = scale

	_character_viewport.character.appearance_manager.appearance = _fumo_appearances.staging
	_character_viewport.character.appearance_manager.load_appearance()


func _update_name(new_name: String):
	_fumo_appearances.staging.display_name = new_name
	_fumo_appearances.staging_changed.emit()


func _update_scale(scale: float):
	_fumo_appearances.staging.config.set(&"scale", scale)
	_fumo_appearances.staging_changed.emit()
