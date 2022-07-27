class_name CharacterMotion
extends Node


@export var enabled := true


static func get_id() -> StringName:
	return &""


#func handle_cancel(_ctx: MotionContext):
func handle_cancel(_ctx):
	pass


# TODO: Referencing MotionContext here leads to "cyclic references"
# Maybe GDScript will be able to do this properly later
#func process_motion(_ctx: MotionContext, _delta: float):
func process_motion(_ctx, _delta: float):
	pass
