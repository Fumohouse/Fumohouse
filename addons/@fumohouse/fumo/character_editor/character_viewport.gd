extends SubViewport

## Underlying Appearance to display
@export_enum(&"Active", &"Staging") var appearance_provider: String

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _character: Fumo = %Fumo

@onready var _camera_controller: CameraController = %CameraController


func _ready() -> void:
	match appearance_provider:
		&"Active":
			load_appearance(fumo_appearances.active)
			fumo_appearances.active_changed.connect(load_appearance)
		&"Staging":
			load_appearance(fumo_appearances.staging)
			fumo_appearances.staging_changed.connect(load_appearance)
		_:
			push_error("No FumoAppearances provider selected!")
			return

	_camera_controller.camera_rotation.y = PI
	_character.camera = _camera_controller


func load_appearance(appearance: Appearance):
	_character.appearance_manager.appearance = appearance
	_character.appearance_manager.load_appearance()
