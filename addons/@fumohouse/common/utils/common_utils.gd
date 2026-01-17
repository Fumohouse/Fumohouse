class_name CommonUtils
extends Object
## Common utilities.


## Use a frame delta to generate a weight for [method @GlobalScope.lerpf].
## https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
static func lerp_weight(delta: float, factor := 5e-6) -> float:
	return 1 - factor ** delta


## Returns whether to capture in-game input.
static func do_game_input(this: Node) -> bool:
	return not this.get_viewport().gui_get_focus_owner()


## Get the upright version of a [Basis] (preserving only Y rotation).
static func basis_upright(basis: Basis) -> Basis:
	return Basis.from_euler(Vector3(0, basis.get_euler(EULER_ORDER_ZXY).y, 0))


## Format the given vector as a string (2 decimal places).
static func format_vector3(vec: Vector3) -> String:
	return "(%.2f %.2f %.2f)" % [vec.x, vec.y, vec.z]


## Apply drag to a velocity vector.
static func apply_drag(vec: Vector3, coeff: float, delta: float) -> Vector3:
	return vec.move_toward(Vector3.ZERO, coeff * vec.length() * delta)


## Wait for UI to update during long-running operations.
static func wait_for_ui_update(node: Node):
	for i in 2:
		await node.get_tree().process_frame


## Get the [AABB] in world space of the given [param node]. Optionally exclude
## nodes from the interior search.
## https://www.reddit.com/r/godot/comments/18bfn0n/comment/mcvw7cl/
static func get_aabb(node: Node3D, exclude: Array[Node] = [], do_transform := false) -> AABB:
	var bounds := AABB()

	if node is VisualInstance3D:
		bounds = (node as VisualInstance3D).get_aabb()

	for child in node.get_children():
		if child is not Node3D or exclude.has(child):
			continue
		var child_bounds := get_aabb(child, exclude, true)
		if bounds.size == Vector3.ZERO:
			bounds = child_bounds
		else:
			bounds = bounds.merge(child_bounds)

	if do_transform:
		bounds = node.transform * bounds

	return bounds
