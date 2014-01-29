precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_rgb;
uniform vec3 u_color_mask;

void main() {
	gl_FragColor = vec4(texture2D(u_rgb, v_texture_position).rgb * u_color_mask, 1.0);
}