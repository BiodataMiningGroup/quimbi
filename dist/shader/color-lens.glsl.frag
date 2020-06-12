precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_rgb;

uniform vec2 u_channel_bounds_r;
//uniform vec2 u_channel_bounds_g;

void main() {
	vec4 intensities = texture2D(u_rgb, v_texture_position);

	intensities.r = (intensities.r - u_channel_bounds_r[0])
		/ (u_channel_bounds_r[1] - u_channel_bounds_r[0]);
	//intensities.g = (intensities.g - u_channel_bounds_g[0])
	//	* u_channel_bounds_g[1];

	gl_FragColor = intensities;
}
