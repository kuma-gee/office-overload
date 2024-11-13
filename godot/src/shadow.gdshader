shader_type canvas_item;

uniform vec4 color: source_color = vec4(0.0);
uniform float blur = 0.0;

void fragment() {
	COLOR = color;
}