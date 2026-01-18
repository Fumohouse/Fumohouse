class_name CharacterInterpolatorMotionProcessor
extends CharacterMotionProcessor
## Handles interpolating between current and authoritative state.

const ID := &"interpolator"

## How long interpolation should take to reach the desired target.
var time := 0.12
## How far away a character needs to be to teleport them rather than
## interpolating.
var teleport_threshold := 3.0

var _active := false
var _basis_offset := Basis.IDENTITY
var _last_basis := Basis.IDENTITY
var _translate_offset := Vector3.ZERO
var _last_translate := Vector3.ZERO
var _progress := 0.0


func _init():
	id = ID


func _process(delta: float, cancelled: bool):
	if ctx.is_replay or not _active:
		return

	ctx.messages[CharacterMoveMotionProcessor.CANCEL_UPRIGHTING] = true

	_progress = move_toward(_progress, 1.0, delta / time)

	var new_basis_offset := Basis.IDENTITY.slerp(_basis_offset, _progress)
	var new_translate_offset: Vector3 = _translate_offset * _progress
	ctx.add_offset(new_translate_offset - _last_translate)
	# This multiplication order seems odd but it works
	ctx.new_basis = ctx.new_basis * new_basis_offset * _last_basis.inverse()

	_last_basis = new_basis_offset
	_last_translate = new_translate_offset

	if _progress == 1.0:
		_active = false


## Set the target transform of this interpolator.
func set_target(target: Transform3D):
	var global_transform := state.node.global_transform
	if global_transform.is_equal_approx(target):
		return

	var translate_offset: Vector3 = target.origin - global_transform.origin
	if translate_offset.length_squared() > teleport_threshold * teleport_threshold:
		state.node.global_transform = target
		return

	_basis_offset = global_transform.basis.inverse() * target.basis
	_last_basis = Basis.IDENTITY
	_translate_offset = translate_offset
	_last_translate = Vector3.ZERO
	_progress = 0.0
	_active = true
