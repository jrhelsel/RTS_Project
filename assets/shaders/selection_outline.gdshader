//meant to be used as a second pass shader

shader_type spatial;

render_mode cull_front, unshaded;

uniform bool outline_enabled = false;
uniform float outline_thickness = 5;
uniform vec4 outline_color : source_color = vec4(1.0);


void vertex() {
	if (outline_enabled){
		VERTEX += normalize(VERTEX) * outline_thickness;
	}
}

void fragment() {
	if (outline_enabled){
		ALBEDO = outline_color.rgb;
	}
}
