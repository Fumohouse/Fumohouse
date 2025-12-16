extends SubViewportContainer

## Underlying Appearance to display
@export_enum(&"Active", &"Staging") var appearance_provider: String
@export var disable_input: bool = false

@onready var character: Fumo = %Fumo

@onready var _fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()

@onready var _subviewport: SubViewport = %SubViewport
@onready var _camera_controller: CameraController = %CameraController


func _ready() -> void:
	match appearance_provider:
		&"Active":
			load_appearance(_fumo_appearances.active)
			_fumo_appearances.active_changed.connect(load_appearance)
		&"Staging":
			load_appearance(_fumo_appearances.staging)
			_fumo_appearances.staging_changed.connect(load_appearance)

	_subviewport.gui_disable_input = disable_input

	_camera_controller.camera_rotation.y = PI
	character.camera = _camera_controller


func load_appearance(appearance: Appearance):
	character.appearance_manager.appearance = appearance
	character.appearance_manager.load_appearance()
