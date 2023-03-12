shader_type spatial;

uniform sampler2D brow_texture : hint_default_transparent;
uniform sampler2D eye_texture : hint_default_transparent;
uniform sampler2D overlay_texture : hint_default_transparent;
uniform sampler2D shine_texture : hint_default_transparent;
uniform sampler2D mouth_texture : hint_default_transparent;

uniform vec4 eye_tint : source_color = vec4(1.0);

/// DITHER
const float VIEWPORT_REF_SIZE = 1080.0;
uniform sampler2D dither_texture : filter_nearest, hint_default_white;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
/// END DITHER

void blend(vec4 brow, vec4 eye, vec4 overlay, vec4 shine, vec4 mouth, out vec3 albedo, out float out_alpha) {
	// list is from the highest "layer" to the lowest one
	vec4 order[5] = { shine, mouth, brow, overlay, eye };
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
	out_alpha = min(tot_alpha, 1.0);
}

void fragment() {
	/// DITHER
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	float viewport_scale = VIEWPORT_SIZE.y / VIEWPORT_REF_SIZE;
	vec2 uv_square = SCREEN_UV;
	uv_square.x *= aspect;

	float dither = texture(dither_texture, uv_square * viewport_scale).r;

	if (alpha < dither)
		discard;
	/// END DITHER

	vec4 brow = texture(brow_texture, UV.xy);
	vec4 eye = texture(eye_texture, UV.xy);
	vec4 overlay = texture(overlay_texture, UV.xy);
	vec4 shine = texture(shine_texture, UV.xy);
	vec4 mouth = texture(mouth_texture, UV.xy);

	vec4 eye_color = eye * eye_tint;

	blend(brow, eye_color, overlay, shine, mouth, ALBEDO, ALPHA);
}
