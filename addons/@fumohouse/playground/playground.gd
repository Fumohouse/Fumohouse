extends Node3D
## Initialization for [Character] test scene.

@onready var _cam_controller: CameraController = %CameraController
@onready var _char: Character = %Fumo


func _ready():
	_char.camera = _cam_controller
