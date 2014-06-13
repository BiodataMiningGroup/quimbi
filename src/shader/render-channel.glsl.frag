precision mediump float;

varying vec2 v_texture_position;

uniform float u_channel;

uniform sampler2D u_region_mask;

const vec4 ONES = vec4(0);
const vec4 ZEROS = vec4(0);

<%=TEXTURE_3D=%>

void main() {
    // if masked by the region mask, don't do anything
    if (texture2D(u_region_mask, v_texture_position).a == 0.0) {
        gl_FragColor = ZEROS;
        return;
    }

    // index of the tile the desired channel is on
    float tile = floor(u_channel / 4.0);
    int channel_on_tile = int(mod(u_channel, 4.0));

    // mask to eliminate all other channels but channel_on_tile
    vec4 mask = vec4(0.0, 0.0, 0.0, 0.0);
    mask[channel_on_tile] = 1.0;

    vec4 colors = glmvilib_texture3D(v_texture_position, tile);
    colors *= mask;

    float channel_color = dot(colors, ONES);

    gl_FragColor = vec4(channel_color, channel_color, channel_color, 1.0);
}
