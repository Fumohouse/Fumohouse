// https://gamedev.stackexchange.com/a/114416
vec2 sphere_map(vec3 vec) {
	return vec2(
		atan(vec.x / vec.z) / TAU + 0.5,
		vec.y * 0.5 + 0.5
	);
}