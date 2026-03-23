shader_type canvas_item;

uniform float scroll_speed : hint_range(0.05, 1.0) = 0.15;
uniform vec3 grid_color : source_color = vec3(1.0, 0.0, 0.6);
uniform vec3 sky_top : source_color = vec3(0.02, 0.01, 0.08);
uniform vec3 sky_bottom : source_color = vec3(0.08, 0.01, 0.15);
uniform vec3 horizon_color : source_color = vec3(0.4, 0.0, 0.35);
uniform float horizon_pos : hint_range(0.3, 0.8) = 0.55;
uniform float horizon_glow : hint_range(0.0, 0.15) = 0.06;
uniform int grid_lines_h : hint_range(6, 30) = 14;
uniform int grid_lines_v : hint_range(6, 30) = 16;
uniform float line_fade : hint_range(0.5, 4.0) = 1.5;
uniform float pulse_intensity : hint_range(0.0, 0.5) = 0.15;

void fragment() {
	vec2 uv = UV;
	float t = TIME;

	// Céu: gradiente vertical
	vec3 col;
	if (uv.y < horizon_pos) {
		float sky_t = uv.y / horizon_pos;
		col = mix(sky_top, sky_bottom, sky_t * sky_t);
		// Glow no horizonte
		float glow = exp(-pow((uv.y - horizon_pos) / horizon_glow, 2.0));
		col += horizon_color * glow * 0.6;
	} else {
		// Chão: escuro com perspectiva
		float floor_t = (uv.y - horizon_pos) / (1.0 - horizon_pos);
		col = mix(vec3(0.06, 0.0, 0.1), vec3(0.02, 0.0, 0.04), floor_t);

		// Perspectiva: mapear UV pra coordenadas do chão
		float depth = floor_t + 0.001; // evitar divisão por zero
		float perspective_z = 1.0 / depth;
		float perspective_x = (uv.x - 0.5) * perspective_z;

		// Linhas horizontais (perpendiculares ao olhar) — scrollam
		float hz = perspective_z * float(grid_lines_h) * 0.08 - t * scroll_speed * 8.0;
		float h_line = abs(fract(hz) - 0.5) * 2.0;
		float h_alpha = pow(1.0 - h_line, line_fade * 12.0);
		// Fade com distância
		float dist_fade = smoothstep(0.0, 0.3, floor_t);
		h_alpha *= dist_fade;

		// Linhas verticais (radiais do ponto de fuga)
		float vz = perspective_x * float(grid_lines_v) * 0.25;
		float v_line = abs(fract(vz) - 0.5) * 2.0;
		float v_alpha = pow(1.0 - v_line, line_fade * 12.0);
		v_alpha *= dist_fade;

		// Pulso sutil
		float pulse = 1.0 + sin(t * 1.5) * pulse_intensity;

		// Combinar linhas
		float grid_alpha = max(h_alpha, v_alpha) * 0.5 * pulse;
		col += grid_color * grid_alpha;

		// Glow no horizonte por baixo
		float glow_below = exp(-floor_t * 8.0);
		col += horizon_color * glow_below * 0.3;
	}

	COLOR = vec4(col, 1.0);
}
