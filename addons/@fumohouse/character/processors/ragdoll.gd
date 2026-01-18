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
	# Keep this processor so seats are synced
	if state.is_remote:
		return

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


func _state_serde(serde: SerDe):
	var curr_seat_path: String = String(_current_seat.get_path()) if _current_seat else ""
	var seat_path := serde.str(curr_seat_path)
	if curr_seat_path != seat_path:
		if _current_seat:
			_current_seat.occupant = null
			_current_seat = null
			state.set_ragdoll(false)
		if not seat_path.is_empty():
			var seat_node := state.node.get_node_or_null(seat_path) as Seat
			_current_seat = seat_node
			state.set_ragdoll(true)
			if seat_node:
				state.state = state.state | CharacterMotionState.CharacterState.SITTING
				seat_node.occupant = state.node

	_seat_debounce_left = serde.f64(_seat_debounce_left)

	var curr_last_seat_path: String = String(_last_seat.get_path()) if _last_seat else ""
	var last_seat_path := serde.str(curr_last_seat_path)
	if curr_last_seat_path != last_seat_path:
		if last_seat_path.is_empty():
			_last_seat = null
		else:
			_last_seat = state.node.get_node_or_null(last_seat_path) as Seat


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
