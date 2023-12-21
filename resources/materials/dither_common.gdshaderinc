#define DITHER_UNIFORMS \
    const float VIEWPORT_REF_SIZE = 1080.0; \
    uniform sampler2D dither_texture : filter_nearest, hint_default_white; \
    uniform float alpha : hint_range(0.0, 1.0) = 1.0;

#define DITHER_FRAGMENT \
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y; \
	float viewport_scale = VIEWPORT_SIZE.y / VIEWPORT_REF_SIZE; \
	vec2 uv_square = SCREEN_UV; \
	uv_square.x *= aspect; \
    \
	float dither = texture(dither_texture, uv_square * viewport_scale).r; \
    \
	if (alpha < dither) \
		discard;
