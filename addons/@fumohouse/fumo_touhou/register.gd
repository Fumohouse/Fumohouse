extends Node

const _DEFAULT_PRESET := preload(
	"res://addons/@fumohouse/fumo_touhou/resources/presets/doremy.tres"
)


func _ready():
	FumoFaceDatabase.get_singleton().scan_dir(
		"res://addons/@fumohouse/fumo_touhou/resources/face_styles"
	)
	FumoPartDatabase.get_singleton().scan_dir(
		"res://addons/@fumohouse/fumo_touhou/resources/part_data"
	)

	var fm := FumoAppearances.get_singleton()
	fm.active = _DEFAULT_PRESET.duplicate(true)
	fm.staging = _DEFAULT_PRESET.duplicate(true)

	fm.scan_dir("res://addons/@fumohouse/fumo_touhou/resources/presets")
