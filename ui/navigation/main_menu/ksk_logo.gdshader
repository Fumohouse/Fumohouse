shader_type canvas_item;

uniform float progress : hint_range(0, 1) = 0.0;
uniform float begin_scale = 0.9;
uniform float end_scale = 1.0;
uniform sampler2D base;
uniform sampler2D anim;
uniform vec4 default_color : source_color = vec4(1.0);

void fragment() {
    vec2 uv = (UV - 0.5) / mix(begin_scale, end_scale, progress) + 0.5;
    vec4 base_color = texture(base, uv);
	vec4 anim_color = texture(anim, uv);

    if (anim_color.a < 0.001) {
        COLOR = vec4(mix(default_color.rgb, base_color.rgb, progress), base_color.a * COLOR.a);
    } else {
        const float sharpness = 10.0;
        const float start_factor = 5.0;
        float factor = min(1.0, (progress - anim_color.r) * sharpness + 1.0) * smoothstep(0.0, 1.0, progress * start_factor);
        COLOR = vec4(mix(default_color.rgb, base_color.rgb, factor), base_color.a * COLOR.a);
    }
}
