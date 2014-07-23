precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_rgb;
uniform sampler2D u_color_map_r;
uniform sampler2D u_color_map_g;
uniform sampler2D u_color_map_b;

uniform vec3 u_color_mask;

const vec3 ONES = vec3(1);

void main() {
	vec3 intensities = texture2D(u_rgb, v_texture_position).rgb;

	float normalization = float(dot(u_color_mask, ONES));

	vec3 color_r = u_color_mask.r *
		texture2D(u_color_map_r, vec2(intensities.r, 0.5)).rgb;

	vec3 color_g = u_color_mask.g *
		texture2D(u_color_map_g, vec2(intensities.g, 0.5)).rgb;

	vec3 color_b = u_color_mask.b *
		texture2D(u_color_map_b, vec2(intensities.b, 0.5)).rgb;

	// remove intensities that should be masked
	// (otherwise they would affect the h/b output value)
	intensities *= u_color_mask;

	gl_FragColor = vec4(
		(color_r.r + color_g.r + color_b.r) / normalization,
		(color_r.g + color_g.g + color_b.g) / normalization,
		(intensities.r * color_r.b + intensities.g * color_g.b +
			intensities.b * color_b.b) / float(dot(intensities, ONES)),
		1.0
	);
}