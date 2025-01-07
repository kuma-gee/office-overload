shader_type canvas_item;

uniform vec3 color: source_color = vec3(0.0);
uniform float blur = 0.0;

void fragment() {
	COLOR.rgb = color;
}