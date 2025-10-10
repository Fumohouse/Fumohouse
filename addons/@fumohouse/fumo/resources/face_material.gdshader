shader_type spatial;

#include "res://addons/@fumohouse/common/resources/materials/dither_common.gdshaderinc"
#include "res://addons/@fumohouse/common/resources/materials/dissolve_common.gdshaderinc"

uniform vec4 skin_color : source_color = vec4(1.0);

uniform sampler2D brow_texture : hint_default_transparent;
uniform sampler2D eye_texture : hint_default_transparent;
uniform sampler2D overlay_texture : hint_default_transparent;
uniform sampler2D shine_texture : hint_default_transparent;
uniform sampler2D mouth_texture : hint_default_transparent;

uniform vec4 eye_tint : source_color = vec4(1.0);

DITHER_UNIFORMS
DISSOLVE_UNIFORMS

void vertex() {
	DISSOLVE_VERTEX
}

void blend(vec4 brow, vec4 eye, vec4 overlay, vec4 shine, vec4 mouth, out vec3 albedo) {
	// list is from the highest "layer" to the lowest one
	vec4 order[6] = { shine, mouth, brow, overlay, eye, skin_color };
	vec3 output = vec3(0.0);

	float max_mult = 1.0;
	float tot_alpha = 0.0;

	for (int i = 0; i < order.length(); i++) {
		if (max_mult <= 0.0)
			break;

		vec4 color = order[i];
		if (color.a == 0.0)
			continue;

		tot_alpha += color.a;

		float mult = min(color.a, max_mult);
		output += color.rgb * mult;
		max_mult -= mult;
	}

	albedo = output;
}

void fragment() {
	DITHER_FRAGMENT

	vec4 brow = texture(brow_texture, UV.xy);
	vec4 eye = texture(eye_texture, UV.xy);
	vec4 overlay = texture(overlay_texture, UV.xy);
	vec4 shine = texture(shine_texture, UV.xy);
	vec4 mouth = texture(mouth_texture, UV.xy);

	vec4 eye_color = eye * eye_tint;

	blend(brow, eye_color, overlay, shine, mouth, ALBEDO);

	DISSOLVE_FRAGMENT
}
