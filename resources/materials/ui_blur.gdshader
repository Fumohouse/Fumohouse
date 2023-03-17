shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float blur : hint_range(0.0, 4.0) = 1.0;
uniform float dim : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec4 screen_color = textureLod(screen_texture, SCREEN_UV, blur);
    COLOR = vec4(mix(screen_color.rgb, vec3(0.0), dim), 1.0);
}
