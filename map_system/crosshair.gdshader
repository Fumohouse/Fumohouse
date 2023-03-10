shader_type canvas_item;

uniform sampler2D crosshair_texture : hint_default_transparent;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    COLOR = vec4(1.0 - texture(screen_texture, SCREEN_UV).rgb, texture(crosshair_texture, UV).a);
}
