class_name MotionContext


# Non changing
var character: Character

# Input
var was_grounded: bool

var input_direction: Vector3
var cam_basis_flat: Basis

# State

# List of motion processor IDs which should be cancelled.
# Order of processing matters.
var cancelled_processors: Array[StringName] = []

# States which don't really make sense to be applied
# (i.e. WALKING when CLIMBING)
var cancelled_states: int = 0

# Output
var new_state: int = Character.CharacterState.NONE
var offset: Vector3
var angular_offset: float


func cancel(processor_class):
	cancelled_processors.append(processor_class.get_id())
