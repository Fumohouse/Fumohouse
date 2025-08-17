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
