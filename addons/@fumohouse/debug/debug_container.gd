extends Control
## A container singleton that holds global debug UIs.


func _ready():
	_fix_order.call_deferred()


func _fix_order():
	reparent(get_tree().root)
	move_to_front()
