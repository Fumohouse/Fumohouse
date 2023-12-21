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

#define DISSOLVE_FRAGMENT \
    float dissolve_cutoff = texture(dissolve_noise, object_pos.xy).r; \
    if (dissolve > dissolve_cutoff) \
        discard; \
    if (dissolve > 0.0 && dissolve > dissolve_cutoff - dissolve_border) \
        EMISSION += dissolve_emission * dissolve_emission_energy;
