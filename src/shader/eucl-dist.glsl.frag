precision mediump float;

varying vec2 v_texture_position;

uniform vec2 u_mouse_position;
uniform float u_normalization;

uniform float u_channel_mask_dimension;
uniform float u_inv_channel_mask_dimension;

uniform sampler2D u_channel_mask;
uniform sampler2D u_region_mask;

const vec4 ONES = vec4(1);
const vec4 ZEROS = vec4(0);

<%=SAMPLER_DEFINITION=%>

void main() {
	// if masked by the region mask, din't do anything
	if (texture2D(u_region_mask, v_texture_position).a == 0.0) {
		gl_FragColor = ZEROS;
		return;
	}

	// Euclidean distance/L2-norm
	float color = 0.0;

	vec4 test_for_zero = vec4(0);

	// temporary texture values of current position
	vec4 current;
	// temporary texture values of sample position
	vec4 sample;

	// the index of the current tile
	float tile;
	// the texture position on the channel mask of the current tile
	vec2 mask_position = vec2(0);
	// the channel mask of the current tile
	vec4 channel_mask;

	// the row-major index of the current tile on it's texture
	float index_on_sampler;
	// the column in which the current tile lies on the texture
	float column;
	// the row in which the current tile lies on the texture
	float row;
	// the index of the texture, the current tile is on
	float sampler_index;

	// the 2d coordinates of the current position on the correct texture
	vec2 coords_2d_current;
	// the 2d coordinates of the sample position on the correct texture
	vec2 coords_2d_sample;

	for (int i = 0; i < <%=TILES=%>; i++) {
		tile = float(i);
		mask_position.s = mod(tile, u_channel_mask_dimension);
		mask_position.t = floor(tile * u_inv_channel_mask_dimension);
		mask_position *= u_inv_channel_mask_dimension;
		channel_mask = texture2D(u_channel_mask, mask_position);
		// check if any channels of this tile are to be computed
		if (dot(channel_mask, ONES) == 0.0) continue;

		index_on_sampler = mod(tile, <%=TILES_PER_TEXTURE=%>);
		column = mod(index_on_sampler, <%=TILE_COLUMNS=%>);
		row = floor(index_on_sampler / <%=TILE_COLUMNS=%>);

		coords_2d_sample = vec2(
			<%=TILE_WIDTH=%> * (column + u_mouse_position.x),
			<%=TILE_HEIGHT=%> * (row + u_mouse_position.y)
		);

		coords_2d_current = vec2(
			<%=TILE_WIDTH=%> * (column + v_texture_position.x),
			<%=TILE_HEIGHT=%> * (row + v_texture_position.y)
		);

		// needed for DYNAMIC_SAMPLER_QUERIES
		sampler_index = floor(tile / <%=TILES_PER_TEXTURE=%>);

		// get rgba of the pixel to compare; filtered by the channel mask and
		// get rgba of the position of this pixel; filtered by the channel mask
		<%=DYNAMIC_SAMPLER_QUERIES
		sample = channel_mask * texture2D(<%=SAMPLER=%>, coords_2d_sample);
		current = channel_mask * texture2D(<%=SAMPLER=%>, coords_2d_current);
		=%>

		test_for_zero += current;

		current -= sample;
		current *= current;
		color += dot(current, ONES);
	}

	// if the intensities of this fragment are all 0, don't draw it
	if (dot(test_for_zero, ONES) == 0.0) discard;

	color = sqrt(color) * u_normalization;

	gl_FragColor = vec4(vec3(1.0 - color), 1.0);
}
