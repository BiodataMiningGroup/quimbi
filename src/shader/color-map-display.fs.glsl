precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_rgb;
uniform sampler2D u_color_map;

void main() {
	float color = texture2D(u_rgb, v_texture_position).r;
	gl_FragColor = texture2D(u_color_map, vec2(color, 0.5));
}