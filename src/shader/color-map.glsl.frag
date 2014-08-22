precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_rgb_color_lens;
uniform sampler2D u_color_map_r;
uniform sampler2D u_color_map_g;

uniform vec3 u_color_mask;

const vec3 ONES = vec3(1);

void main() {
	vec4 intensities = texture2D(u_rgb_color_lens, v_texture_position);

	vec3 color_r = u_color_mask.r *
		texture2D(u_color_map_r, vec2(intensities.r, 0.5)).rgb;

	vec3 color_g = u_color_mask.g *
		texture2D(u_color_map_g, vec2(intensities.g, 0.5)).rgb;

	// more intuitive color mixing
	if (color_r.b - color_g.b < -0.5) {
		color_r.b += 1.0 * u_color_mask.r; // dont add if this channel isnt used
	} else if (color_g.b - color_r.b < -0.5) {
		color_g.b += 1.0 * u_color_mask.g; // dont add if this channel isnt used
	}

	vec3 mixed_color = (intensities.r * color_r + intensities.g * color_g) /
		float(dot(intensities.rgb, u_color_mask));

	mixed_color.b = mod(mixed_color.b, 1.0);

	gl_FragColor = vec4(mixed_color, intensities.a);
}