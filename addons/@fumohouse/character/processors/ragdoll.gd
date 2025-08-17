class_name CharacterRagdollMotionProcessor
extends CharacterMotionProcessor
## Handles entering ragdoll mode.

const ID := &"ragdoll"

## Minimum time (seconds) between dismounting and mounting the same seat.
var seat_debounce := 3.0

var _current_seat: Seat
var _last_seat: Seat
var _seat_debounce_left := 0.0


func _init():
	id = ID


func _process(delta: float, _cancelled: bool):
	_handle_state(ctx.motion.sit, CharacterMotionState.CharacterState.SITTING)

	# Seat handling
	if _current_seat != null:
		# Dismount
		if not state.is_ragdoll:
			_last_seat = _current_seat
			_seat_debounce_left = seat_debounce

			_current_seat.occupant = null
			_current_seat = null

			# Restore body mode
			state.set_ragdoll(false)
	else:
		# Debounce
		if _seat_debounce_left > 0.0:
			_seat_debounce_left = maxf(0.0, _seat_debounce_left - delta)
			if _seat_debounce_left == 0.0:
				_last_seat = null

		# Find seat
		if not state.is_ragdoll and not state.is_dead():
			for body in ctx.body_intersections:
				if body is Seat and (not _last_seat or body != _last_seat):
					var seat := body as Seat
					if not seat.occupant:
						state.set_ragdoll(true)
						ctx.set_state(CharacterMotionState.CharacterState.SITTING)
						ctx.cancel_processor(CharacterMoveMotionProcessor.ID)

						seat.occupant = state.node
						_current_seat = seat


func _handle_state(action: bool, char_state: CharacterMotionState.CharacterState):
	if action:
		if state.is_state(char_state):
			state.set_ragdoll(false)
		else:
			ctx.set_state(char_state)
			state.set_ragdoll(true)
	elif state.is_ragdoll and state.is_state(char_state):
		# Maintain state
		ctx.set_state(char_state)
