shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform int pixel_size : hint_range(1, 8) = 3;

void fragment() {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel = vec2(float(pixel_size)) / screen_size;
	vec2 uv = floor(SCREEN_UV / pixel) * pixel + pixel * 0.5;
	COLOR = texture(screen_texture, uv);
}
