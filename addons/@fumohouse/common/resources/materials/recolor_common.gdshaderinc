// Common code for recoloring with a mask.
// The multiplier on each channel (R, G, B) is determined by the recolor color
// and mask.
// 1.0 on the mask means to apply the full recolor to that channel. 0.0 means
// to multiply the channel by 1.0 (i.e., no change).
// RECOLOR_UNIFORMS: Place alongside other uniforms.
// RECOLOR_FRAGMENT: Place at the bottom of the fragment shader.

#define RECOLOR_UNIFORMS \
	group_uniforms Recolor; \
	uniform vec4 recolor : source_color = vec4(1.0); \
	uniform sampler2D texture_recolor_mask : hint_default_white; \
	group_uniforms;

#define RECOLOR_FRAGMENT \
	vec4 recolor_tex = texture(texture_recolor_mask, UV); \
	ALBEDO *= mix(vec3(1.0), recolor.rgb, recolor_tex.rgb); //\
	//ALPHA *= mix(1.0, recolor.a, recolor_tex.a);
