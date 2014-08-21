precision mediump float;

varying vec2 v_texture_position;

// index of the tile the desired channel is on
uniform float u_tile;
// filters out every channel but the desired one
uniform vec4 u_channel_mask;

uniform sampler2D u_region_mask;

const vec4 ONES = vec4(1);
const vec4 ZEROS = vec4(0);

<%=TEXTURE_3D=%>

void main() {
    // if masked by the region mask, don't do anything
    if (texture2D(u_region_mask, v_texture_position).a == 0.0) {
        gl_FragColor = ZEROS;
        return;
    }

    vec4 colors = glmvilib_texture3D(v_texture_position, u_tile);
    colors *= u_channel_mask;

    float channel_color = dot(colors, ONES);

    gl_FragColor = vec4(vec3(channel_color), (channel_color == 0.0) ? 0.0 : 1.0);
}
