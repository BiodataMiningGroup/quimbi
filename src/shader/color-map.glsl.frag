precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_rgb_color_lens;
uniform sampler2D u_color_map_r;
uniform sampler2D u_color_map_g;
uniform sampler2D u_color_map_b;

uniform vec3 u_color_mask;

const vec3 ONES = vec3(1);

void main() {
	vec4 intensities = texture2D(u_rgb_color_lens, v_texture_position);

	vec3 color_r = u_color_mask.r *
		texture2D(u_color_map_r, vec2(intensities.r, 0.5)).rgb;

	vec3 color_g = u_color_mask.g *
		texture2D(u_color_map_g, vec2(intensities.g, 0.5)).rgb;

	vec3 color_b = u_color_mask.b *
		texture2D(u_color_map_b, vec2(intensities.b, 0.5)).rgb;

	gl_FragColor = vec4(vec3((intensities.r * color_r +
		intensities.g * color_g + intensities.b * color_b) /
		float(dot(intensities.rgb, u_color_mask))),
		intensities.a
	);
}