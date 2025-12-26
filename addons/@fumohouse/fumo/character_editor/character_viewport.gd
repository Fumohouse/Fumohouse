extends TextureRect

@export var disable_input: bool = false

@onready var character: Fumo = %Fumo

@onready var _subviewport: SubViewport = %SubViewport
@onready var _camera_controller: CameraController = %CameraController


func _ready() -> void:
	texture = _subviewport.get_texture()
	_subviewport.gui_disable_input = disable_input

	_scale_viewport()
	get_window().size_changed.connect(_scale_viewport)
	resized.connect(_scale_viewport)

	_camera_controller.camera_rotation.y = PI

	character.appearance_manager.base_camera_offset = 2.0
	character.camera = _camera_controller


func _scale_viewport():
	var window := get_window()
	var scale := (window.size as Vector2) / (window.content_scale_size as Vector2)
	_subviewport.size = size * max(scale.x, scale.y)


func _gui_input(event: InputEvent) -> void:
	var window := get_window()
	var scale := (window.size as Vector2) / (window.content_scale_size as Vector2)

	if event is InputEventMouse:
		event.position *= scale
	if event is InputEventMouseMotion:
		event.relative *= scale

	_subviewport.push_input(event, true)
	accept_event()
