class_name MotionContext


# Non changing
var character: Character

# Input
var was_grounded: bool

# Output
var new_state: int = Character.CharacterState.NONE
var offset: Vector3
