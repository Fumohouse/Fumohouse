extends SubViewport


@onready var _character: Fumo = %Fumo

@onready var _camera_controller: CameraController = %CameraController

@onready var fumo_appearances: FumoAppearances = FumoAppearances.get_singleton()


func _ready() -> void:
	load_appearance()
	fumo_appearances.staging_changed.connect(load_appearance)

	_camera_controller.camera_rotation.y = PI
	_character.camera = _camera_controller
	#_character.state.ctx.motion = _character._get_motion()


func load_appearance(appearance: Appearance = fumo_appearances._staging):
	_character.appearance_manager.appearance = appearance
	_character.appearance_manager.load_appearance()
