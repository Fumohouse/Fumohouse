class_name FumoAnimatorMotionProcessor
extends CharacterMotionProcessor
## Animator for [Fumo].

const ID := &"fumo_animator"


func _init():
	id = ID


func _initialize():
	pass


func _process(delta: float, cancelled: bool):
	if cancelled:
		return
