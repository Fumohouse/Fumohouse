class_name Spawnpoint
extends Node3D
## Node defining a location where players can spawn.

## A marker marking the exact spawn location.
@export var point: Marker3D


func get_spawn_point() -> Transform3D:
	return point.global_transform
