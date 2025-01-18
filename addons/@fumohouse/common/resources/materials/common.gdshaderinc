// https://gamedev.stackexchange.com/a/114416
vec2 sphere_map(vec3 vec) {
	return vec2(
		atan(vec.x / vec.z) / TAU + 0.5,
		vec.y * 0.5 + 0.5
	);
}

// Nvidia's "empirical approximation" of the fresnel effect:
// https://developer.download.nvidia.com/CgTutorial/cg_tutorial_chapter07.html
vec3 fresnel(vec3 color_reflected, vec3 color_refracted, float bias, float scale, float power, vec3 view, vec3 normal) {
	float reflection_coeff = clamp(bias + scale * pow(1.0 + dot(view, normal), power), 0.0, 1.0);
	return reflection_coeff * color_reflected + (1.0 - reflection_coeff) * color_refracted;
}

// Converts depth (e.g. from a depth texture) to a linear value in view space.
// https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html
// TODO: Only works on Vulkan. ndc.z is in range [-1.0, 1.0] on OpenGL.
float linear_depth(mat4 inv_projection_matrix, vec2 screen_uv, float depth) {
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}
