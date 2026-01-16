extends Control

## Camera to bind to.
@export var camera: Camera3D

## Shape of the camera to use as its collider.
@export var camera_shape: SphereShape3D


func _process(_delta: float):
	var direct_space_state := camera.get_world_3d().direct_space_state
	var camera_transform := camera.global_transform

	# Query for intersection
	var intersect_params := PhysicsShapeQueryParameters3D.new()
	intersect_params.shape = camera_shape
	intersect_params.transform = camera_transform
	intersect_params.collide_with_bodies = false
	intersect_params.collide_with_areas = true

	var intersect_result: Array[Dictionary] = direct_space_state.intersect_shape(intersect_params)
	if intersect_result.is_empty():
		hide()
		return

	var water_collider: Area3D = null
	for data in intersect_result:
		var collider := data["collider"] as Area3D
		if collider.is_in_group(&"water"):
			water_collider = collider
			break

	if not water_collider:
		hide()
		return

	# Check depth with ray
	var ray_params := PhysicsRayQueryParameters3D.new()
	ray_params.from = camera_transform.origin + Vector3.UP * camera_shape.radius
	ray_params.to = ray_params.from + Vector3.DOWN * (2 * camera_shape.radius)
	ray_params.collide_with_bodies = false
	ray_params.collide_with_areas = true

	var ray_result: Dictionary = direct_space_state.intersect_ray(ray_params)
	if not ray_result.is_empty() and ray_result["collider"] == water_collider:
		# Not underwater
		hide()
		return

	show()
