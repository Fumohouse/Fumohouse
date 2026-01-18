class_name Character
extends RigidBody3D
## A modular, networked character controller.

## Fired when [member camera] changes.
signal camera_updated(new_camera: CameraController)

## If [code]true[/code], processing for this character is disabled.
@export var disabled := false

## This character's multiplayer mode.
@export var multiplayer_mode: CharacterMotionState.MultiplayerMode = (
	CharacterMotionState.MultiplayerMode.SINGLEPLAYER
)

var _camera: CameraController
## The current camera controller focused on this character.
var camera: CameraController:
	set = set_camera,
	get = get_camera

## This character's motion state.
var state := CharacterMotionState.new()

@onready var _collider: CollisionShape3D = $Collider


func _ready():
	state.multiplayer_mode = multiplayer_mode
	state.node = self
	state.rid = get_rid()

	state.collider = _collider

	state.initialize()

	_update_camera()


func _physics_process(delta: float):
	if disabled:
		return

	state.update(_get_motion(), delta)


## Setter for [member camera].
func set_camera(value: CameraController):
	if _camera:
		_camera.focus_node = null
	_camera = value
	_update_camera()


## Getter for [member camera].
func get_camera() -> CameraController:
	return _camera


func _update_camera():
	if not is_inside_tree() or not _camera:
		return
	_camera.focus_node = self
	camera_updated.emit(_camera)


func _get_motion() -> CharacterMotionState.Motion:
	if not _camera:
		return null

	var motion := CharacterMotionState.Motion.new()
	if CommonUtils.do_game_input(self) and not state.is_dead():
		motion.direction = Input.get_vector(
			&"move_left", &"move_right", &"move_forward", &"move_backward"
		)
		motion.jump = Input.is_action_pressed(&"move_jump")
		motion.run = Input.is_action_pressed(&"move_run")
		motion.sit = Input.is_action_just_pressed(&"move_sit")
	else:
		motion.direction = Vector2.ZERO
		motion.jump = false
		motion.run = false
		motion.sit = false

	motion.camera_rotation = camera.camera_rotation
	motion.camera_mode = camera.mode

	return motion
