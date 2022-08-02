class_name CharacterAnimator
extends Node


enum MainTransition {
	BASE,
	IDLE,
	SIT,
	HORIZONTAL,
	VERTICAL,
}


enum VerticalTransition {
	FALL,
	CLIMB,
}


const WALK_SPEED := "parameters/walk_speed/scale"
const CLIMB_SPEED := "parameters/climb_speed/scale"

const TRANSITION_MAIN := "parameters/main/current"
const TRANSITION_VERTICAL := "parameters/vertical/current"

const JUMP := "parameters/jump_oneshot/active"

var _states := {
	Character.CharacterState.CLIMBING: {
		TRANSITION_MAIN: MainTransition.VERTICAL,
		TRANSITION_VERTICAL: VerticalTransition.CLIMB,
		JUMP: false,
	},
	Character.CharacterState.FALLING: {
		TRANSITION_MAIN: MainTransition.VERTICAL,
		TRANSITION_VERTICAL: VerticalTransition.FALL,
		JUMP: false,
	},
	Character.CharacterState.JUMPING: {
		TRANSITION_MAIN: MainTransition.VERTICAL,
		TRANSITION_VERTICAL: VerticalTransition.FALL,
		JUMP: true,
	},
	Character.CharacterState.WALKING: {
		TRANSITION_MAIN: MainTransition.HORIZONTAL,
	},
	Character.CharacterState.IDLE: {
		TRANSITION_MAIN: MainTransition.IDLE,
	},
}

@export_range(0, 1) var min_state_time := 0

@onready var _character: Character = $".."
@onready var _horizontal_motion: HorizontalMotion = $"../HorizontalMotion"
@onready var _ladder_motion: LadderMotion = $"../LadderMotion"
@onready var _animator: AnimationTree = $"../Rig/Armature/AnimationTree"

var _state := Character.CharacterState.NONE


func _physics_process(_delta: float):
	var velocity_flat := _character.velocity
	velocity_flat.y = 0

	_animator.set(WALK_SPEED, velocity_flat.length() / _horizontal_motion.movement_speed)
	_animator.set(CLIMB_SPEED, 1.0 if _ladder_motion.is_moving else 0.0)

	for state in _states.keys():
		if not _character.is_state(state):
			continue

		if _state == state:
			break

		_state = state

		var properties: Dictionary = _states[state]
		for key in properties.keys():
			_animator.set(key, properties[key])

		break
