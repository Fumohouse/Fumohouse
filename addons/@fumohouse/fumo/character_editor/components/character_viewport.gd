extends ViewportRect

@onready var character: Fumo = %Fumo
@onready var _camera_controller: CameraController = %CameraController


func _ready():
	super()

	_camera_controller.camera_rotation.y = PI

	character.appearance_manager.base_camera_offset = 2.0
	character.camera = _camera_controller
