// NOTE: Shader automatically converted from Godot Engine 4.0.alpha12's StandardMaterial3D.

// For approximate parity with glTF imported materials, Emission, AO, and Normal Map
// are turned on before StandardMaterial3D conversion to shader.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
//uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
uniform sampler2D texture_emission : source_color, hint_default_black,filter_linear_mipmap,repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy;
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_scale : hint_range(-16,16);
uniform sampler2D texture_ambient_occlusion : hint_default_white, filter_linear_mipmap,repeat_enable;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
//uniform vec3 uv2_scale;
//uniform vec3 uv2_offset;

/// DITHER
const float VIEWPORT_REF_SIZE = 1080.0;
uniform sampler2D dither_texture : filter_nearest, hint_default_white;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
/// END DITHER

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
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

	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	NORMAL_MAP = texture(texture_normal,base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	vec3 emission_tex = texture(texture_emission,base_uv).rgb;
	EMISSION = (emission.rgb+emission_tex)*emission_energy;
	AO = dot(texture(texture_ambient_occlusion,base_uv),ao_texture_channel);
	AO_LIGHT_AFFECT = ao_light_affect;
}
