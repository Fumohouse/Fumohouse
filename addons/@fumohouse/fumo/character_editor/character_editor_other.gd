extends ScrollContainer

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _rig_color: ColorPickerButton = %RigColorPicker

@onready var _pitch_slider: HSlider = %PitchSlider
@onready var _pitch_value: Label = %PitchValue
@onready var _low_pitch: Button = %LowPitch
@onready var _base_pitch: Button = %BasePitch
@onready var _high_pitch: Button = %HighPitch


func _ready():
	_rig_color.color = _fumo_appearances.staging.config.get(
		&"rig_color", Color(0.988, 0.918, 0.831)
	)
	_rig_color.color_changed.connect(_on_rig_color_changed)

	_pitch_slider.value_changed.connect(_set_pitch)
	_set_pitch(_fumo_appearances.staging.config.get(&"voice_pitch", 1.25))

	_low_pitch.pressed.connect(_set_pitch.bind(1.1))
	_base_pitch.pressed.connect(_set_pitch.bind(1.25))
	_high_pitch.pressed.connect(_set_pitch.bind(1.4))


func _on_rig_color_changed(color: Color):
	_fumo_appearances.staging.config[&"rig_color"] = color
	_fumo_appearances.staging_changed.emit()


func _set_pitch(new_pitch: float):
	_fumo_appearances.staging.config[&"voice_pitch"] = new_pitch
	_fumo_appearances.staging_changed.emit()
	_pitch_slider.value = new_pitch
	_pitch_value.text = "%.2f" % new_pitch
