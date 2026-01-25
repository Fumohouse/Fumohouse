extends PathFollow3D
## A node that follows a [Path3D] at constant speed.

## The offset of this platform, in meters.
@export_range(0.0, 100.0, 0.1, "suffix:m") var offset := 0.0

## The speed to follow at, in meters per second.
@export_range(0.0, 10.0, 0.1, "suffix:m/s") var speed := 5.0


func _physics_process(delta: float):
	progress = speed * WorldClock.get_singleton().physics_time + offset
