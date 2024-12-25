shader_type spatial;
render_mode unshaded;

uniform sampler2D reticle;
uniform vec4 reticle_color : source_color;
uniform float reticle_size = 1.0;

void fragment() {
	vec2 pixelPositionClipSpace = (SCREEN_UV - 0.5) * 2.0; // in clip space top left is (-1,-1) and bottom right is (1,1)
	vec3 normalViewSpaceNormalized = NORMAL / NORMAL.z; // normal is by default in view space; divide by z so we have z=1
	float ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y; // screen ratio
	float slope = -1.0 / PROJECTION_MATRIX[1][1]; // in 1m distance from the camera, how high is the top pixel row above the camera?

	// without multiplying by 'vec2(ratio,1.0)' the width of the reticle would be wrong and dependent on screen width
	vec2 UV_new = ((pixelPositionClipSpace + vec2(normalViewSpaceNormalized.x / (ratio * slope), -normalViewSpaceNormalized.y / slope)) / reticle_size) * vec2(ratio,1.0) + vec2(0.5,0.5);

	UV_new = clamp(UV_new, vec2(0,0), vec2(1,1));

	vec4 col = texture(reticle, UV_new);
	ALBEDO = col.rgb * reticle_color.rgb;
	ALPHA = col.a * reticle_color.a;
}