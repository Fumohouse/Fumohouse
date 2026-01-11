class_name CharacterIntersectionsMotionProcessor
extends CharacterMotionProcessor
## Finds and stores wall contact and intersections with [CollisionObject3D]s
## or [Area3D]s.

const ID := &"intersections"


func _init():
	id = ID


func _process(_delta: float, _cancelled: bool):
	const WALL_MARGIN := 0.15

	# Walls
	var wall_params := PhysicsTestMotionParameters3D.new()
	wall_params.from = state.node.global_transform
	wall_params.motion = Vector3.ZERO
	wall_params.margin = WALL_MARGIN
	wall_params.recovery_as_collision = true
	wall_params.max_collisions = 4

	var wall_result := PhysicsTestMotionResult3D.new()
	state.test_motion(wall_params, wall_result)

	for i in wall_result.get_collision_count():
		var normal := wall_result.get_collision_normal(i)
		if (
			not state.is_stable_ground(normal)
			and not state.should_push(wall_result.get_collider_rid(i))
		):
			var wall := CharacterMotionState.WallInfo.new()
			wall.point = wall_result.get_collision_point(i)
			wall.normal = wall_result.get_collision_normal(i)
			wall.collider = wall_result.get_collider(i)
			ctx.walls.append(wall)

	# Intersections
	var intersect_params := PhysicsShapeQueryParameters3D.new()
	intersect_params.shape = state.collision_shape
	intersect_params.collision_mask = state.node.collision_mask
	intersect_params.transform = state.collider.global_transform
	intersect_params.collide_with_areas = true
	intersect_params.collide_with_bodies = true
	intersect_params.margin = state.margin
	intersect_params.exclude = [state.rid]

	var intersect_result: Array[Dictionary] = (
		state.node.get_world_3d().direct_space_state.intersect_shape(intersect_params)
	)

	for data in intersect_result:
		var collider := data["collider"] as Object

		if collider is Area3D:
			ctx.area_intersections.append(collider as Area3D)
		elif collider is CollisionObject3D:
			ctx.body_intersections.append(collider as CollisionObject3D)
