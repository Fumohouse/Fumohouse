extends ViewportRect

@onready var character: Fumo = %Fumo
@onready var camera_controller: CameraController = %CameraController


func _ready():
	super()

	camera_controller.camera_rotation.y = PI

	character.appearance_manager.base_camera_offset = 2.0
	character.camera = camera_controller
