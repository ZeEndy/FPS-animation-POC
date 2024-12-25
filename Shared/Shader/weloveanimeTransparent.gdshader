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
	// Vertex Color Use as Albedo: Enabled
	albedo_tex *= COLOR;
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA = Alpha;
	//METALLIC = 1.0;
}
void light(){
	float dotproduct = clamp(dot(NORMAL,LIGHT),-0.9,0.9);
	float sample = clamp((dotproduct+1.0)* ATTENUATION * 0.47,0.05,0.95);
	vec4 shade = texture(LightGrad,vec2(sample,0.0));
	DIFFUSE_LIGHT += (shade.rgb*clamp(LIGHT_COLOR,0,1));

}