class_name WorldClock
extends Node
## Local or synchronized clock.

const _PHYSICS_SYNC_THRESH := 0.1  # s

## Current clock time (seconds).
var time: float:
	get:
		if _nm and _nm.is_active:
			return _nm.time / 1e6
		return _process_time

## Current physics time (seconds).
var physics_time: float:
	get:
		return _physics_time

var _process_time := 0.0
var _physics_time := 0.0

@onready var _nm := NetworkManager.get_singleton()


static func get_singleton() -> WorldClock:
	return Modules.get_singleton(&"WorldClock") as WorldClock


func _process(delta: float):
	_process_time += delta


func _physics_process(delta: float):
	if abs(_physics_time - _nm.time / 1e6) > _PHYSICS_SYNC_THRESH:
		_physics_time = _nm.time / 1e6
	_physics_time += delta
