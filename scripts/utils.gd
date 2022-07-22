class_name Utils
extends Object

# https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
static func lerp_weight(delta: float, factor: float = 5e-6) -> float:
	return 1 - pow(factor, delta)
