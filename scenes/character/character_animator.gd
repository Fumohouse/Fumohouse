class_name CharacterAnimator
extends Node


const WALK_SPEED := "parameters/walk/walk_speed/scale"

@export_range(0, 1) var min_state_time := 0.02

@onready var _character: Character = $".."
@onready var _horizontal_motion: HorizontalMotion = $"../HorizontalMotion"
@onready var _animator: AnimationTree = $"../Rig/Armature/AnimationTree"
@onready var _playback: AnimationNodeStateMachinePlayback = _animator.get("parameters/playback")

var _nodes := {
	Character.CharacterState.CLIMBING: "climb",
	Character.CharacterState.FALLING: "fall",
	Character.CharacterState.JUMPING: "jump",
	Character.CharacterState.WALKING: "walk",
	Character.CharacterState.IDLE: "idle",
}

var _state := Character.CharacterState.NONE
var _state_time := 0.0


func _physics_process(delta: float):
	var velocity_flat := _character.velocity
	velocity_flat.y = 0

	_animator.set(WALK_SPEED, velocity_flat.length() / _horizontal_motion.movement_speed)

	for state in _nodes.keys():
		if not _character.is_state(state):
			continue

		if state != _state:
			_state = state
			_state_time = 0

		_state_time += delta
		if _state_time > min_state_time:
			_playback.travel(_nodes[state])

		break
