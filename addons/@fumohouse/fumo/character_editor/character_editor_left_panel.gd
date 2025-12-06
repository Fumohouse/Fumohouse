extends VBoxContainer

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _active_label: Label = %ActiveLabel

@onready var _apply_button: Button = %ApplyButton

@onready var _scale_slider: HSlider = %ScaleSlider

@onready var _scale_label: Label = %ScaleLabel


func _ready():
	_update_label(fumo_appearances.staging)
	fumo_appearances.staging_changed.connect(_update_label)

	_apply_button.pressed.connect(fumo_appearances.apply)

	_scale_slider.value_changed.connect(_update_scale)


func _update_label(appearance: Appearance):
	_active_label.text = appearance.display_name
	_scale_label.text = "%.f%%" % (appearance.config.get(&"scale") * 100)


func _update_scale(scale: float):
	fumo_appearances.with_staging(func(staging: Appearance):
		staging.config.set(&"scale", scale)
	)
