precision mediump float;

varying vec2 v_texture_position;

uniform vec2 u_mouse_position;
uniform float u_normalization;

const int LAST_CHANNELS = <%=CHANNELS_LAST_TILE=%>;
const int TILES_MINUS_ONE = <%=TILES=%> - 1;
const vec4 ONES = vec4(1);

<%=TEXTURE_3D=%>

void main() {
	// Euclidean distance/L2-norm
	float color = 0.0;

	vec4 test_for_zero = vec4(0);

	vec4 sample;
	vec4 current;

	for (int i = 0; i < TILES_MINUS_ONE; i++) {
		sample = glmvilib_texture3D(vec3(u_mouse_position, i));
		current = glmvilib_texture3D(vec3(v_texture_position, i));

		test_for_zero += current;

		current -= sample;
		current *= current;
		color += dot(current, ONES);
	}

	// last tile
	sample = glmvilib_texture3D(vec3(u_mouse_position, TILES_MINUS_ONE));
	current = glmvilib_texture3D(vec3(v_texture_position, TILES_MINUS_ONE));

	test_for_zero += current;

	// if the intensities of this fragment are all 0, don't draw it
	if (dot(test_for_zero, ONES) == 0.0) discard;

	current -= sample;
	current *= current;

	for (int i = 0; i < LAST_CHANNELS; i++) {
		color += current[i];
	}

	color = sqrt(color) * u_normalization;

	gl_FragColor = vec4(vec3(1.0 - color), 1.0);
}