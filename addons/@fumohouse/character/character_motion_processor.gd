class_name CharacterMotionProcessor
extends RefCounted
## An abstract type that represents a component of a character's motion.
##
## Each processor should have a constant named [code]ID[/code] that is equal to
## [member id].

## A unique ID for this processor type. Should be equal to a constant under the
## same class named [code]ID[/code].
var id := &"INVALID"

## The [CharacterMotionState] managing this processor.
var state: CharacterMotionState
## Convenience access to the context of [member state].
var ctx: CharacterMotionState.Context:
	get:
		return state.ctx


## Called when [member state] is ready.
func _initialize():
	pass


## Per-frame process function.
func _process(_delta: float, _cancelled: bool):
	pass


## Get the approximate velocity induced by this processor, as a [Vector3], or
## [code]null[/code] if not applicable at this time.
func _get_velocity() -> Variant:
	return null
