extends VBoxContainer

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _active_label: Label = %ActiveLabel

@onready var _apply_button: Button = %ApplyButton

@onready var _scale_slider: HSlider = %ScaleSlider

@onready var _scale_label: Label = %ScaleLabel


func _ready():
	_update_panel(fumo_appearances.staging)
	fumo_appearances.staging_changed.connect(_update_panel)

	_apply_button.pressed.connect(fumo_appearances.apply)

	_scale_slider.value_changed.connect(_update_scale)


func _update_panel(appearance: Appearance):
	_active_label.text = appearance.display_name

	var scale = appearance.config.get(&"scale")
	_scale_label.text = "%.f%%" % (scale * 100)
	# does not appear to cause a circular dependency as value_changed doesn't fire back to this
	_scale_slider.value = scale


func _update_scale(scale: float):
	fumo_appearances.with_staging(func(staging: Appearance):
		staging.config.set(&"scale", scale)
	)
