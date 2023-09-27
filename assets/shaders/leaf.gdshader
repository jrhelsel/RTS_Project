shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, depth_prepass_alpha, specular_toon;

uniform float transform_factor : hint_range(0,1);
uniform sampler2D leaf_texture : source_color;

void vertex() {
	vec2 centered_UV = UV * 2.0 - 1.0;
	centered_UV.y *= -1.0;
	vec4 offset_UV = vec4(centered_UV, 0, 0) * VIEW_MATRIX;
	vec4 final_transform = offset_UV * MODEL_MATRIX;
	VERTEX += final_transform.xyz * transform_factor;
	COLOR = vec4(UV,0,1);
}

void fragment() {
	vec4 leaf_tex = texture(leaf_texture, UV);
	ALBEDO = vec3(18.0/255.0, 30.0/255.0, 0.0/255.0);
	ALPHA = round(leaf_tex.r);
}
