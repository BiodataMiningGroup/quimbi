precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_distances;
uniform sampler2D u_rgb;
uniform vec3 u_color_mask;

void main() {
	vec3 saved_color = texture2D(u_rgb, v_texture_position).rgb * (1.0 - u_color_mask);
	vec3 new_color = texture2D(u_distances, v_texture_position).rgb * u_color_mask;
	gl_FragColor = vec4(saved_color + new_color, 1.0);
}