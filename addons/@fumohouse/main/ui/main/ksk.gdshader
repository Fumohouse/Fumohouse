// https://godotshaders.com/shader/desaturation-shader/ (ombarus, CC0)
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0);
uniform float brightness;
uniform float begin_scale = 0.9;
uniform float end_scale = 1.0;
uniform sampler2D logo;

void fragment() {
	vec2 uv = (UV - 0.5) / mix(begin_scale, end_scale, progress) + 0.5;
	vec4 tex_color = texture(logo, uv);
	vec3 desaturated = vec3(dot(tex_color.rgb, vec3(0.299, 0.587, 0.114)));

    COLOR.rgb = mix(desaturated * brightness, tex_color.rgb, progress);
	COLOR.a *= tex_color.a;
}
