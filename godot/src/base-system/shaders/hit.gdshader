shader_type canvas_item;

uniform bool enable = false;

uniform vec4 hit_color : source_color = vec4(1.0);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	if (enable && COLOR.r < 0.5) { // right now only used for darker colors, so it's fine
		COLOR.rgb = hit_color.rgb;
	}
}
