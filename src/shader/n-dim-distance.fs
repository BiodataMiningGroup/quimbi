// "<%= =%>" will be assigned/replaced during shader loading

precision mediump float;

// the uniform sampler
<%=SAMPLER_DEF=%>
// sampler from render to texture framebuffer texture
uniform sampler2D <%=RTT_SAMPLER=%>;
// position of the cursor
uniform vec2 u_currpos;
// the current render state
uniform int u_state;
// distance computing method
uniform int u_method;

// the texCoords passed in from the vertex shader.
varying vec2 v_texCoord;

const int NO_TILES = <%=NO_TILES=%>;
const float NO_TILES_PER_SAMPLER = <%=NO_TILES_PER_SAMPLER=%>;
const float MINK_NORMALIZATION = <%=MINK_NORMALIZATION=%>;
const float ANGLE_NORMALIZATION = <%=ANGLE_NORMALIZATION=%>;
const int NO_LAST_CHANNELS = <%=NO_LAST_CHANNELS=%>;
const float NO_TILES_PER_ROW = <%=NO_TILES_PER_ROW=%>;
const float TILE_HEIGHT = <%=TILE_HEIGHT=%>;
const float TILE_WIDTH = <%=TILE_WIDTH=%>;

// helpers
const vec4 ones = vec4(1.0, 1.0, 1.0, 1.0);
const int no_tiles_minus_one = NO_TILES - 1;

// fetches the vec4 of the current coordinates from the texture
// with respect to the z-coordinate (the tile in the texture)		
vec4 getVec4_3D(vec3 coords) {
	float indexOnSampler = mod(coords.z, NO_TILES_PER_SAMPLER);

	float xTile = mod(indexOnSampler, NO_TILES_PER_ROW);
	float yTile = floor(indexOnSampler / NO_TILES_PER_ROW);

	vec2 coords2d = vec2(
		// TILE_WIDTH * xTile + TILE_WIDTH * coords.x
		TILE_WIDTH * (xTile + coords.x),
		// TILE_HEIGHT * yTile + TILE_HEIGHT * coords.y
		TILE_HEIGHT * (yTile + coords.y)
	);

	float samplerNo = floor(coords.z / NO_TILES_PER_SAMPLER);
	// choose the right sampler to pick the color vecor
	// no if else, because of stack overflow on some systems
	<%=SAMPLER_LOOKUP=%>

	return vec4(0, 0, 0, 0);
}

// Minkowski distance/L2-norm
float dMink() {
	float ret = 0.0;
	// // to check wether all sample values are 0
	float controlSample = 0.0;
	// to check wether all current values are 0
	float controlCurrent = 0.0;

	vec4 sample;
	vec4 current;

	// iterate over all tiles except the last
	for (int i = 0; i < no_tiles_minus_one; i++) {
		// get rgba of the pixel to compare
		sample = getVec4_3D(vec3(u_currpos, i));
		// get rgba of the position of this pixel
		current = getVec4_3D(vec3(v_texCoord, i));

		// sum of sample vector elements, first, because current can be fetched
		// simultaniously
		controlSample += dot(sample, ones);
		// sum of current vector elements
		controlCurrent += dot(current, ones);

		current -= sample;
		// manual power, because pow() doesn't take negative arguments
		current *= current;

		// sum of current vector elements
		ret += dot(current, ones);
	}

	// last tile (may use not all channels)
	current = getVec4_3D(vec3(v_texCoord, no_tiles_minus_one));
	sample = getVec4_3D(vec3(u_currpos, no_tiles_minus_one));
	// take the whole vector because unused channels will be 0 anyway
	controlSample += dot(sample, ones);
	controlCurrent += dot(current, ones);
	
	current -= sample;
	// manual power, because pow() doesn't take negative arguments
	current *= current;

	// calculate only with used channels of last tile
	for (int i = 0; i < NO_LAST_CHANNELS; i++) {
		ret += current[i];
	}

	//if the sample or current vector contained only 0
	if (u_method == 11 && (controlSample == 0.0 || controlCurrent == 0.0)) {
		return 1.0;
	}

	// normalized with the inverse of the maximal occuring euclidean
	// distance in this image
	return sqrt(ret) * MINK_NORMALIZATION;
}

// angle between the two vectors
// <A,B> = ||A|| * ||B|| * cos(angle)
// => angle = acos(<A,B>/(||A||*||B||))
float dAngle() {
	float ret = 0.0;
	// cummulating the squared length of this pixels vector
	float currentLength = 0.0;
	// cummulating the squared length of the sample pixels vector
	float sampleLength = 0.0;
	vec4 current;
	vec4 sample;

	for (int i = 0; i < no_tiles_minus_one; i++) {
		// get rgba of the pixel to compare
		sample = getVec4_3D(vec3(u_currpos, i));
		// get rgba of the position of this pixel
		current = getVec4_3D(vec3(v_texCoord, i));

		currentLength += dot(current, current);
		sampleLength += dot(sample, sample);
		ret += dot(current, sample);
	}

	// last tile (may use not all channels)
	current = getVec4_3D(vec3(v_texCoord, no_tiles_minus_one));
	sample = getVec4_3D(vec3(u_currpos, no_tiles_minus_one));

	for (int i = 0; i < NO_LAST_CHANNELS; i++) {
		// use MAD (multiply, then add) -> single cycle operation
		currentLength = (current[i] * current[i]) + currentLength;
		sampleLength = (sample[i] * sample[i]) + sampleLength;
		ret = (current[i] * sample[i]) + ret;
	}

	ret *= inversesqrt(currentLength * sampleLength);

	// normalized with 1/(pi/2) beacuse pi/2 is the maximal possible angle
	return acos(ret) * ANGLE_NORMALIZATION;
}

void main() {
	//vec4 tex = texture2D(u_sampler0, v_texCoord);gl_FragColor = tex;
	//vec4 tex = getVec4_3D(vec3(v_texCoord, 1));gl_FragColor = tex;
	
	float dist = 1.0;
	vec4 tmp_color = vec4(0.0, 0.0, 0.0, 1.0);

	if (u_method >= 0 && u_method < 10) {
		dist = 1.0 - dAngle();
	} else if (u_method >= 10 && u_method < 20) {
		dist = 1.0 - dMink();
	}

	if (u_state == 0) {
		// display grayscale image
		tmp_color = vec4(dist, dist, dist, 1.0);
	} else if (u_state == -2) {
		// clear rttTexture
		// don't change tmp_color
	} else {
		int tmp_state = u_state;

		if (tmp_state >= 30) {
			// vary B channel
			tmp_color.b = dist;
			tmp_state -= 30;
		} else if (tmp_state >= 20) {
			// vary G channel
			tmp_color.g = dist;
			tmp_state -= 20;
		} else if (tmp_state >= 10) {
			// vary R channel
			tmp_color.r = dist;
			tmp_state -= 10;
		}

		if (tmp_state == 0) {
			gl_FragColor = tmp_color;
			return;
		}

		// works without adjusting the texture coordinates to the current scale
		// because the viewport is set to original size before every
		// rtt draw call
		vec4 rtt = texture2D(<%=RTT_SAMPLER=%>, v_texCoord);

		// add rtt B channel
		if (tmp_state >= 4) {
			tmp_color.b = rtt.b;
			tmp_state -= 4;
		}

		// add rtt G channel
		if (tmp_state >= 2) {
			tmp_color.g = rtt.g;
			tmp_state -= 2;
		}

		// add rtt R channel
		if (tmp_state >= 1) {
			tmp_color.r = rtt.r;
			tmp_state -= 1;
		}
	}

	gl_FragColor = tmp_color;
}