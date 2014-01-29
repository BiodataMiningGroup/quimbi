precision mediump float;

varying vec2 v_texture_position;

uniform vec2 u_mouse_position;
uniform float u_normalization;

const int LAST_CHANNELS = <%=CHANNELS_LAST_TILE=%>;
const int TILES_MINUS_ONE = <%=TILES=%> - 1;

<%=TEXTURE_3D=%>

void main() {
	// angle between the two vectors
	// <A,B> = ||A|| * ||B|| * cos(angle)
	// => angle = acos(<A,B>/(||A||*||B||))
	float color = 0.0;

	// cummulating the squared length of this pixels vector
	float currentLength = 0.0;
	// cummulating the squared length of the sample pixels vector
	float sampleLength = 0.0;

	vec4 current;
	vec4 sample;

	for (int i = 0; i < TILES_MINUS_ONE; i++) {
		// get rgba of the pixel to compare
		sample = glmvilib_texture3D(vec3(u_mouse_position, i));
		// get rgba of the position of this pixel
		current = glmvilib_texture3D(vec3(v_texture_position, i));

		currentLength += dot(current, current);
		sampleLength += dot(sample, sample);
		color += dot(current, sample);
	}

	// last tile (may use not all channels)
	current = glmvilib_texture3D(vec3(v_texture_position, TILES_MINUS_ONE));
	sample = glmvilib_texture3D(vec3(u_mouse_position, TILES_MINUS_ONE));

	for (int i = 0; i < LAST_CHANNELS; i++) {
		// use MAD (multiply, then add) -> single cycle operation
		currentLength = (current[i] * current[i]) + currentLength;
		sampleLength = (sample[i] * sample[i]) + sampleLength;
		color = (current[i] * sample[i]) + color;
	}

	// if the intensities of this fragment are all 0, don't draw it
	if (currentLength == 0.0) discard;

	color *= inversesqrt(currentLength * sampleLength);

	// normalized with 1/(pi/2) beacuse pi/2 is the maximal possible angle
	color = acos(color) * u_normalization;

	gl_FragColor = vec4(vec3(1.0 - color), 1.0);
}