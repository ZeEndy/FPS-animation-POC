// NOTE: Shader automatically converted from Godot Engine 4.3.rc2's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;


void fragment() {
	ALBEDO = vec3(0.0);
}