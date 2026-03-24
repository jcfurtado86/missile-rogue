shader_type canvas_item;

uniform float line_spacing : hint_range(1.0, 8.0) = 4.0;
uniform float line_alpha : hint_range(0.0, 1.0) = 0.35;
uniform float flicker_speed : hint_range(0.0, 4.0) = 0.8;
uniform float flicker_amount : hint_range(0.0, 0.1) = 0.04;

void fragment() {
	float y = FRAGCOORD.y;
	float scanline = step(0.5, fract(y / line_spacing));
	float flicker = sin(TIME * flicker_speed) * flicker_amount;
	COLOR = vec4(0.0, 0.0, 0.0, scanline * (line_alpha + flicker));
}
