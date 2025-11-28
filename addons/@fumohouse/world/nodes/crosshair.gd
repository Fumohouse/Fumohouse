extends Control

## Camera controller to bind to
@export var camera_controller: CameraController


func _ready():
	_on_camera_controller_mode_changed(camera_controller.mode)
	camera_controller.mode_changed.connect(_on_camera_controller_mode_changed)


func _on_camera_controller_mode_changed(mode: CameraController.CameraMode):
	visible = (
		mode == CameraController.CameraMode.MODE_FIRST_PERSON
		or mode == CameraController.CameraMode.MODE_FLOATING
	)
