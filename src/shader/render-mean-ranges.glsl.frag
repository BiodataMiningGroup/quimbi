precision mediump float;

varying vec2 v_texture_position;

uniform float u_channel_mask_dimension;
uniform float u_inv_channel_mask_dimension;
uniform sampler2D u_channel_mask;

uniform float u_inv_active_channels;

uniform sampler2D u_region_mask;

const int LAST_CHANNELS = <%=CHANNELS_LAST_TILE=%>;
const int TILES_MINUS_ONE = <%=TILES=%> - 1;
const vec4 ONES = vec4(1);
const vec4 ZEROS = vec4(0);

<%=TEXTURE_3D=%>

void main() {
    // if masked by the region mask, don't do anything
    if (texture2D(u_region_mask, v_texture_position).a == 0.0) {
        gl_FragColor = ZEROS;
        return;
    }

    float color = 0.0;
    vec4 current;

    float tile;
    vec2 mask_position = vec2(0);
    vec4 channel_mask;

    for (int i = 0; i < TILES_MINUS_ONE; i++) {
        tile = float(i);
        mask_position.s = mod(tile, u_channel_mask_dimension);
        mask_position.t = floor(tile * u_inv_channel_mask_dimension);
        mask_position *= u_inv_channel_mask_dimension;
        channel_mask = texture2D(u_channel_mask, mask_position);
        // check if any channels of this tile are to be computed
        if (dot(channel_mask, ONES) == 0.0) continue;

        // get rgba of the position of this pixel; filtered by the channel mask
        current = channel_mask * glmvilib_texture3D(v_texture_position, tile);

        color += dot(current, ONES);
    }

    tile = float(TILES_MINUS_ONE);
    mask_position.s = mod(tile, u_channel_mask_dimension);
    mask_position.t = floor(tile * u_inv_channel_mask_dimension);
    mask_position *= u_inv_channel_mask_dimension;
    channel_mask = texture2D(u_channel_mask, mask_position);

    // last tile (may use not all channels)
    current = channel_mask * glmvilib_texture3D(v_texture_position, tile);
    for (int i = 0; i < LAST_CHANNELS; i++) {
        color += current[i];
    }

    // build average
    color *= u_inv_active_channels;

    gl_FragColor = vec4(vec3(color), (color == 0.0) ? 0.0 : 1.0);
}
