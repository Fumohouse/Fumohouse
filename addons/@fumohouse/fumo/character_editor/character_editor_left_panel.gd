extends VBoxContainer

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _active_label: Label = %ActiveLabel

@onready var _apply_button: Button = %ApplyButton


func _ready():
	_update_label(fumo_appearances.staging)
	fumo_appearances.staging_changed.connect(_update_label)
	_apply_button.pressed.connect(fumo_appearances.apply)


func _update_label(appearance: Appearance):
	_active_label.text = appearance.display_name
