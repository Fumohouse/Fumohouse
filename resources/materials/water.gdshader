// General-purpose water shader.
// Based on a few examples:
// - https://godotshaders.com/shader/realistic-water/ (godotshaders, MIT)
// - https://www.youtube.com/watch?v=7L6ZUYj1hs8 (StayAtHomeDev)
// - https://catlikecoding.com/unity/tutorials/flow/looking-through-water/ and
//   https://catlikecoding.com/unity/tutorials/flow/waves/ (Catlike Coding/Jasper Flick, MIT-0)

shader_type spatial;
render_mode shadows_disabled;

#include "common.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

group_uniforms Material;
uniform vec4 albedo : source_color = vec4(1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.2;
uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform float roughness : hint_range(0.0, 1.0) = 0.2;

group_uniforms FresnelEffect;
uniform vec3 fresnel_color : source_color = vec3(1.0);
uniform vec3 fresnel_settings = vec3(-0.3, 0.6, 2.5); // bias, scale, power

group_uniforms Depth;
uniform vec3 fog_color : source_color = vec3(0.0);
uniform float fog_density : hint_range(0.0, 2.0) = 0.5;

uniform vec3 foam_color : source_color = vec3(1.0);
uniform float foam_distance : hint_range(0.0, 2.0) = 0.1;

group_uniforms NormalMap;
uniform sampler2D normal_map_1 : hint_normal;
uniform sampler2D normal_map_2 : hint_normal;
uniform float normal_factor : hint_range(0.0, 1.0) = 0.5;
uniform vec2 normal_map_1_movement = vec2(0.1, 0.1);
uniform vec2 normal_map_2_movement = vec2(-0.05, -0.1);

uniform float refraction_strength : hint_range(0.0, 1.0) = 0.005;

group_uniforms Waves;
uniform vec4 wave_1 = vec4(1.0, 0.0, 0.1, 5.0);
uniform vec4 wave_2 = vec4(0.3, 0.5, 0.25, 3.5);
uniform vec4 wave_3 = vec4(-0.7, 0.2, 0.2, 2.5);

// Implementation of https://en.wikipedia.org/wiki/Trochoidal_wave based on Catlike Coding article
// - Assume infinite depth (tanh(k_m*h)->1)
// - No phase shift
vec3 trochoidal_wave(vec4 wave, vec3 point, inout vec3 tangent, inout vec3 binormal) {
    float steepness = wave.z;
    float wavelength = wave.w;

    float k = 2.0 * PI / wavelength; // wavenumber in both directions
    float omega = sqrt(9.8 * k); // angular frequency
    vec2 d = normalize(wave.xy); // direction
    float theta = k * dot(d, point.xz) - omega * TIME;
    float a = steepness / k; // amplitude

    // Found based on partial derivatives (somehow)
    tangent += vec3(
        1.0 - d.x * d.x * steepness * sin(theta),
        d.x * steepness * cos(theta),
        -d.x * d.y * steepness * sin(theta)
    );

    binormal += vec3(
        -d.x * d.y * steepness * sin(theta),
        d.y * steepness * cos(theta),
        1.0 - d.y * d.y * steepness * sin(theta)
    );

    return vec3(
        d.x * a * cos(theta),
        a * sin(theta),
        d.y * a * cos(theta)
    );
}

void vertex() {
    vec3 vertex = VERTEX;
    vec3 tangent = vec3(0.0);
    vec3 binormal = vec3(0.0);

    vertex += trochoidal_wave(wave_1, vertex, tangent, binormal);
    vertex += trochoidal_wave(wave_2, vertex, tangent, binormal);
    vertex += trochoidal_wave(wave_3, vertex, tangent, binormal);

    TANGENT = tangent;
    BINORMAL = binormal;
    NORMAL = normalize(cross(binormal, tangent));
    VERTEX = vertex;
}

void fragment() {
    // Base UVs on both world position and actual mesh UV
    vec2 mesh_uv = UV + NODE_POSITION_WORLD.xz;
    vec3 normal_map = mix(
        texture(normal_map_1, mesh_uv + TIME * normal_map_1_movement).rgb,
        texture(normal_map_2, mesh_uv + TIME * normal_map_2_movement).rgb,
        normal_factor);

    NORMAL_MAP = normal_map;

    // Used for simulated screen-space refraction
    vec2 uv_offset = normal_map.xz * refraction_strength;
    uv_offset.y = uv_offset.x * VIEWPORT_SIZE.y / VIEWPORT_SIZE.x; // Adjust for screen size
    vec2 screen_uv = SCREEN_UV + uv_offset;

    float background_depth = linear_depth(INV_PROJECTION_MATRIX, screen_uv, texture(depth_texture, screen_uv).x);
    float surface_depth = linear_depth(INV_PROJECTION_MATRIX, screen_uv, FRAGCOORD.z);
    float depth_difference = background_depth - surface_depth;

    vec3 color = fresnel(albedo.rgb, fresnel_color, fresnel_settings.x, fresnel_settings.y, fresnel_settings.z, VIEW, NORMAL);

    if (depth_difference < 0.0) {
        // Avoid refraction of objects above water
        screen_uv = SCREEN_UV;
        background_depth = linear_depth(INV_PROJECTION_MATRIX, SCREEN_UV, texture(depth_texture, screen_uv).x);
        depth_difference = background_depth - surface_depth;
    } else {
        // Foam from depth difference
        color = mix(color, foam_color, step(depth_difference, foam_distance));
    }

    ALBEDO = color;

    METALLIC = metallic;
    SPECULAR = specular;
    ROUGHNESS = roughness;

    // Exponential height fog model
    float fog_factor = exp2(-fog_density * depth_difference);
    EMISSION = mix(fog_color, texture(screen_texture, screen_uv).rgb, fog_factor) * (1.0 - albedo.a);
}
