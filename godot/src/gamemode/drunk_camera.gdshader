shader_type canvas_item;

// --- Uniforms --- //
uniform vec2 amplitutde = vec2(1.0, 0.0);
uniform vec2 speed = vec2(1.0, 0.0);

uniform float blur: hint_range(0.0, 1.0, 0.01) = 1.0;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

// --- Functions --- //
void fragment() {
	vec2 pos = mod((UV - amplitutde * sin(TIME + vec2(UV.y, UV.x) * speed)) / TEXTURE_PIXEL_SIZE,
			1.0 / TEXTURE_PIXEL_SIZE) * TEXTURE_PIXEL_SIZE;
	COLOR = texture(SCREEN_TEXTURE, pos);
	
	
	COLOR.rgb = (texture(SCREEN_TEXTURE, pos) + 
			texture(SCREEN_TEXTURE, pos * blur)).rgb / 2.0;
			//texture(SCREEN_TEXTURE, pos * 0.98)).rgb / 3.0;
			//texture(SCREEN_TEXTURE, pos * 0.97 + blur*0.03) +
			//texture(SCREEN_TEXTURE, pos * 0.96 + blur*0.04) +
			//texture(SCREEN_TEXTURE, pos * 0.95 + blur*0.05) +
			//texture(SCREEN_TEXTURE, pos * 0.94 + blur*0.06) +
			//texture(SCREEN_TEXTURE, pos * 0.93 + blur*0.07) +
			//texture(SCREEN_TEXTURE, pos * 0.92 + blur*0.08) +
			//texture(SCREEN_TEXTURE, pos * 0.91 + blur*0.09)).rgb / 10.0;
}