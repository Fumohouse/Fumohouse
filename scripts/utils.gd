class_name Utils


static func get_build_string() -> String:
	return "Prototype Stage"


# https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
static func lerp_weight(delta: float, factor: float = 5e-6) -> float:
	return 1 - pow(factor, delta)
