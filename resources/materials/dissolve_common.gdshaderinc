// Use cull_disabled

#define DISSOLVE_UNIFORMS \
    uniform sampler2D dissolve_noise : hint_default_white; \
    uniform float dissolve : hint_range(0.0, 1.0) = 0.0; \
    uniform float dissolve_border : hint_range(0.0, 1.0) = 0.05; \
    uniform vec3 dissolve_emission : source_color; \
    uniform float dissolve_emission_energy : hint_range(0.0, 10.0) = 4.0; \
    varying vec3 object_pos;

#define DISSOLVE_VERTEX \
    object_pos = VERTEX;

#define PI 3.14159265358979323846

// Cylindrical projection from "sphere" looks better than just swizzling
// https://gamedev.stackexchange.com/a/114416
#define DISSOLVE_FRAGMENT \
    vec3 pos_norm = normalize(object_pos); \
    float u = atan(pos_norm.x, pos_norm.z) / 2.0 / PI + 0.5; \
    float v = pos_norm.y * 0.5 + 0.5; \
    float dissolve_cutoff = texture(dissolve_noise, vec2(u, v)).r; \
    if (dissolve > dissolve_cutoff) \
        discard; \
    if (dissolve > 0.0 && dissolve > dissolve_cutoff - dissolve_border) \
        EMISSION += dissolve_emission * dissolve_emission_energy;
