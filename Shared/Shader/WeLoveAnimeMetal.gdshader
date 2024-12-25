// NOTE: Shader automatically converted from Godot Engine 4.3.rc2's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform sampler2D LightGrad;
uniform sampler2D FrenelGrad;
uniform float Alpha;

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	//vec4 shade = texture(LightGrad,vec2(SSS_TRANSMITTANCE_COLOR.r,0.0));
	AO_LIGHT_AFFECT=1.0;
	albedo_tex *= COLOR;
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	SPECULAR = 0.2;
}
void light(){
	float dotproduct = clamp(dot(NORMAL,LIGHT),-0.9,0.9);
	float sample = clamp((dotproduct+1.0)* ATTENUATION * 0.47,0.05,0.95);
	vec4 shade = texture(LightGrad,vec2(sample,0.0));

	DIFFUSE_LIGHT += shade.rgb*LIGHT_COLOR;//(shade.rgb*clamp(LIGHT_COLOR,0,1));
}
