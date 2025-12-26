extends SubViewportContainer

@export var disable_input: bool = false

@onready var character: Fumo = %Fumo

@onready var _subviewport: SubViewport = %SubViewport
@onready var _camera_controller: CameraController = %CameraController


func _ready() -> void:
	_subviewport.gui_disable_input = disable_input

	_camera_controller.camera_rotation.y = PI

	character.appearance_manager.base_camera_offset = 2.0
	character.camera = _camera_controller
