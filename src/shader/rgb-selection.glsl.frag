precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_distances;
uniform sampler2D u_rgb;
uniform vec3 u_color_mask;

void main() {
	vec4 color_mask = vec4(u_color_mask, 1.0);

	vec4 saved_color = texture2D(u_rgb, v_texture_position) * (1.0 - color_mask);
	vec4 new_color = texture2D(u_distances, v_texture_position) * color_mask;
	gl_FragColor = saved_color + new_color;
}