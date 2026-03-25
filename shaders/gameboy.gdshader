shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform int pixel_size : hint_range(1, 8) = 3;

// Game Boy 4-color palette (darkest → lightest)
const vec3 GB0 = vec3(0.06, 0.22, 0.06);  // #0F380F
const vec3 GB1 = vec3(0.19, 0.38, 0.19);  // #306230
const vec3 GB2 = vec3(0.53, 0.67, 0.19);  // #8BAC0F
const vec3 GB3 = vec3(0.61, 0.74, 0.06);  // #9BBC0F

void fragment() {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel = vec2(float(pixel_size)) / screen_size;
	vec2 uv = floor(SCREEN_UV / pixel) * pixel + pixel * 0.5;
	vec4 col = texture(screen_texture, uv);

	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));

	vec3 gb;
	if (lum < 0.2) {
		gb = GB0;
	} else if (lum < 0.45) {
		gb = GB1;
	} else if (lum < 0.7) {
		gb = GB2;
	} else {
		gb = GB3;
	}

	COLOR = vec4(gb, col.a);
}
