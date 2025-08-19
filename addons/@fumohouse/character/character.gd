class_name Character
extends RigidBody3D
## A modular, networked character controller.

## Fired when [member camera] changes.
signal camera_updated(new_camera: CameraController)

## If [code]true[/code], processing for this character is disabled.
@export var disabled := false

var _camera: CameraController
## The current camera controller focused on this character.
var camera: CameraController:
	set = set_camera,
	get = get_camera

## This character's motion state.
var state := CharacterMotionState.new()
var _motion := CharacterMotionState.Motion.new()

@onready var _main_collider: CollisionShape3D = $MainCollider
@onready var _ragdoll_collider: CollisionShape3D = $RagdollCollider


func _ready():
	state.node = self
	state.rid = get_rid()

	state.main_collider = _main_collider
	state.ragdoll_collider = _ragdoll_collider

	state.initialize()

	_update_camera()


func _physics_process(delta: float):
	if disabled:
		return

	if not _camera:
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
	if CommonUtils.do_game_input(self) and not state.is_dead():
		_motion.direction = Input.get_vector(
			&"move_left", &"move_right", &"move_forward", &"move_backward"
		)
		_motion.jump = Input.is_action_pressed(&"move_jump")
		_motion.run = Input.is_action_pressed(&"move_run")
		_motion.sit = Input.is_action_just_pressed(&"move_sit")
	else:
		_motion.direction = Vector2.ZERO
		_motion.jump = false
		_motion.run = false
		_motion.sit = false

	_motion.camera_rotation = camera.camera_rotation
	_motion.camera_mode = camera.mode

	return _motion
