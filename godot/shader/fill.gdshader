shader_type canvas_item;

uniform float fill: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform vec4 not_fill_color: source_color = vec4(1.0);

void fragment() {
	COLOR.a = 1. - step(fill, UV.x);
}