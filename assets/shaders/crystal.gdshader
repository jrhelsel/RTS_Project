shader_type spatial;
render_mode cull_back;

uniform float metallic : hint_range(0.0, 1.0, 0.01);
uniform float roughness : hint_range(0.0, 1.0, 0.01);
uniform float emission_intensity : hint_range(0.0, 5.0, 0.1);
uniform float fresnel_scale : hint_range(0.0, 1.0, 0.01);
uniform float alpha : hint_range(0.0, 1.0, 0.01);

uniform vec4 base_color : source_color;
uniform vec4 top_color : source_color;
uniform vec4 bottom_color : source_color;

void fragment() {
	float fresnel =  (1.0 - fresnel_scale) + fresnel_scale * sqrt(1.0 - dot(NORMAL, VIEW));

	ROUGHNESS = roughness;
	METALLIC = metallic;
	ALBEDO = base_color.rgb;
	EMISSION = fresnel * top_color.rgb * emission_intensity;
	//ALPHA = alpha;
}
