extends AnimatableBody3D
## A body that rotates constantly in the Y-axis.

## Rotation speed, degrees per second.
@export_range(0.0, 60.0, 1.0, "degrees") var rotation_speed := 5.0


func _physics_process(delta: float):
	rotation.y = deg_to_rad(rotation_speed) * WorldClock.get_singleton().physics_time
