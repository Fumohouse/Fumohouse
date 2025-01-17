// Common code for a dissolve shader.
// DISSOLVE_UNIFORMS: Place alongside other uniforms.
// DISSOLVE_VERTEX: Place in the vertex shader.
// DISSOLVE_FRAGMENT: Place at the botttom of the fragment shader.

#include "common.gdshaderinc"

#define DISSOLVE_UNIFORMS \
	group_uniforms Dissolve; \
	uniform sampler2D dissolve_noise : hint_default_white; \
	uniform float dissolve : hint_range(0.0, 1.0) = 0.0; \
	uniform float dissolve_border : hint_range(0.0, 1.0) = 0.05; \
	uniform vec3 dissolve_emission : source_color; \
	uniform float dissolve_emission_energy : hint_range(0.0, 10.0) = 4.0; \
	group_uniforms; \
	varying vec3 object_pos;

#define DISSOLVE_VERTEX \
	object_pos = VERTEX;

// Cylindrical projection from "sphere" looks better than just swizzling
#define DISSOLVE_FRAGMENT \
	vec2 proj = sphere_map(object_pos); \
	float dissolve_cutoff = texture(dissolve_noise, vec2(proj.x, proj.y)).r; \
	if (dissolve > dissolve_cutoff) \
		discard; \
	if (dissolve > 0.0 && dissolve > dissolve_cutoff - dissolve_border) \
		EMISSION += dissolve_emission * dissolve_emission_energy;
