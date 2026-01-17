class_name FumoAnimatorMotionProcessor
extends CharacterMotionProcessor
## Animator for [Fumo].

const ID := &"fumo_animator"

const _MAIN := "parameters/main/transition_request"
const _MAIN_BASE := "base"
const _MAIN_IDLE := "idle"
const _MAIN_SIT := "sit"
const _MAIN_HORIZONTAL := "horizontal"
const _MAIN_VERTICAL := "vertical"
const _MAIN_SWIM := "swim"
const _MAIN_DEAD := "dead"

const _VERT := "parameters/vertical/transition_request"
const _VERT_FALL := "fall"
const _VERT_CLIMB := "climb"

const _HORIZ := "parameters/horizontal/transition_request"
const _HORIZ_WALK := "walk"
const _HORIZ_RUN := "run"

const _SWIM := "parameters/swimming/transition_request"
const _SWIM_IDLE := "idle"
const _SWIM_SWIM := "swim"

const _DEAD := "parameters/dead/transition_request"
const _DEAD_IDLE := "idle"
const _DEAD_DEATH1 := "death1"

const _WALK_SPEED := "parameters/walk_speed/scale"
const _RUN_SPEED := "parameters/run_speed/scale"
const _CLIMB_SPEED := "parameters/climb_speed/scale"
const _SWIM_SPEED := "parameters/swim_speed/scale"

const _JUMP := "parameters/jump_oneshot/request"

## Minimum time running (s) to transition to running animation. This preventss
## rapid switching between running and walking states.
var min_running_time := 0.15

var _running_time := 0.0

var _fumo: Fumo
var _animator: AnimationTree:
	get:
		return _fumo.animation_tree

var _horizontal_motion: CharacterHorizontalMotionProcessor
var _ladder_motion: CharacterLadderMotionProcessor

var _death_particles: GPUParticles3D

var _state: Variant = null
var _STATES: Array[Dictionary] = [
	{
		"state": CharacterMotionState.CharacterState.DEAD,
		"properties": {_MAIN: _MAIN_DEAD},
		"init": _dead_init,
		"update": _dead_update,
	},
	{
		"state":
		CharacterMotionState.CharacterState.SWIMMING | CharacterMotionState.CharacterState.IDLE,
		"properties":
		{
			_MAIN: _MAIN_SWIM,
			_SWIM: _SWIM_IDLE,
		}
	},
	{
		"state": CharacterMotionState.CharacterState.SWIMMING,
		"properties":
		{
			_MAIN: _MAIN_SWIM,
			_SWIM: _SWIM_SWIM,
		},
		"update": _swim_update,
	},
	{
		"state": CharacterMotionState.CharacterState.SITTING,
		"properties":
		{
			_MAIN: _MAIN_SIT,
		}
	},
	{
		"state": CharacterMotionState.CharacterState.CLIMBING,
		"properties":
		{
			_MAIN: _MAIN_VERTICAL,
			_VERT: _VERT_CLIMB,
			_JUMP: AnimationNodeOneShot.ONE_SHOT_REQUEST_NONE,
		},
		"update": _climbing_update
	},
	{
		"state": CharacterMotionState.CharacterState.FALLING,
		"properties":
		{
			_MAIN: _MAIN_VERTICAL,
			_VERT: _VERT_FALL,
			_JUMP: AnimationNodeOneShot.ONE_SHOT_REQUEST_NONE,
		}
	},
	{
		"state": CharacterMotionState.CharacterState.JUMPING,
		"properties":
		{
			_MAIN: _MAIN_VERTICAL,
			_VERT: _VERT_FALL,
			_JUMP: AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		}
	},
	{
		"state": CharacterMotionState.CharacterState.WALKING,
		"properties":
		{
			_MAIN: _MAIN_HORIZONTAL,
		},
		"update": _walking_update
	},
	{"state": CharacterMotionState.CharacterState.IDLE, "properties": {_MAIN: _MAIN_IDLE}}
]


func _init():
	id = ID


func _initialize():
	_fumo = state.node as Fumo

	_horizontal_motion = _fumo.state.get_motion_processor(CharacterHorizontalMotionProcessor.ID)
	_ladder_motion = _fumo.state.get_motion_processor(CharacterLadderMotionProcessor.ID)

	_death_particles = _fumo.get_node("%DeathParticles")


func _process(delta: float, cancelled: bool):
	if cancelled:
		return

	for state_info in _STATES:
		if not state.is_state(state_info["state"]):
			continue

		if _state == state_info:
			break

		_state = state_info

		if state_info.has("init"):
			state_info["init"].call()

		for key in state_info["properties"]:
			_animator.set(key, state_info["properties"][key])

		break

	if _state != null and _state.has("update"):
		_state["update"].call(delta)


func _dead_init():
	var flake_delay := _dead_update(0.0)
	await _fumo.get_tree().create_timer(flake_delay).timeout

	_death_particles.emitting = true

	var tween := _fumo.create_tween()
	tween.tween_method(_fumo.set_dissolve, 1e-10, 1.0, 2.0)


func _dead_update(_delta: float) -> float:
	if state.is_state(CharacterMotionState.CharacterState.FALLING):
		_animator.set(_DEAD, _DEAD_IDLE)
		return 0.0
	else:
		_animator.set(_DEAD, _DEAD_DEATH1)
		return 1.5


func _swim_update(_delta: float):
	_animator.set(_SWIM_SPEED, ctx.velocity.length() / _horizontal_motion.walk_speed)


func _climbing_update(_delta: float):
	_animator.set(_CLIMB_SPEED, 1.0 if _ladder_motion.is_moving else 0.0)


func _walking_update(delta: float):
	var velocity_flat := Vector3(ctx.velocity.x, 0.0, ctx.velocity.z)
	var horiz_speed := velocity_flat.length()

	const SPEED_THRESHOLD := 0.2

	# Prevent jittery switching between animations (e.g. on stairs)
	if horiz_speed > _horizontal_motion.walk_speed + SPEED_THRESHOLD:
		_running_time += delta
	else:
		_running_time = 0.0

	if _running_time > min_running_time:
		_animator.set(_HORIZ, _HORIZ_RUN)
		_animator.set(_RUN_SPEED, horiz_speed / _horizontal_motion.run_speed)
	else:
		_animator.set(_HORIZ, _HORIZ_WALK)
		_animator.set(_WALK_SPEED, horiz_speed / _horizontal_motion.walk_speed)
