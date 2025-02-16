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
