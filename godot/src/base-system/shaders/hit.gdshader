shader_type canvas_item;

uniform bool enable = false;

uniform vec4 hit_color : source_color = vec4(1.0);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	if (enable && COLOR.r < 0.5) { // right now only used for darker colors, so it's fine
		COLOR.rgb = hit_color.rgb;
	}
}

//shader_type canvas_item;
//
//uniform vec4 shine_color : source_color = vec4(1.0);
//uniform float shine_size : hint_range(0.01, 1.0, 0.01) = 0.1;
//uniform float shine_angle : hint_range(0.0, 89.9, 0.1) = 45.0;
//uniform float shine_speed : hint_range(0.0, 10.0, 0.1) = 1.0;
//uniform bool enable = false;
//
//void fragment() {
	////float h = texture(heightMap,UV).x;
	////h = clamp(floor(h + fill),0.0,1.0);
	////COLOR = vec4(fg_color.rgb,fg_color.a*h);
	//
	////if (COLOR.a <= 0.0) {
		////COLOR = bg_color;
	////}
//
	//if (enable && COLOR.r < 0.5) {
		//float slope = tan(radians(shine_angle));
	    //float shine = step(1.0 - shine_size * 0.1, 0.5 + 0.5 * sin(slope * UV.x - UV.y + -TIME * shine_speed));
		//COLOR.rgb = mix(COLOR.rgb, shine_color.rgb, shine * shine_color.a);
	//}
//}