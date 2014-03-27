precision mediump float;

varying vec2 v_texture_position;

uniform int u_tile_idx;
uniform int u_channel_idx;

const int LAST_CHANNELS = <%=CHANNELS_LAST_TILE=%>;
const int TILES_MINUS_ONE = <%=TILES=%> - 1;
const vec4 ONES = vec4(1);

<%=TEXTURE_3D=%>

void main() {

    float color = 0.0;
    vec4 current;

    for (int i = 0; i < TILES_MINUS_ONE + 1; i++) {
        if (i == u_tile_idx) {
            current = glmvilib_texture3D(vec3(v_texture_position, i));
        }
    }

    for (int i = 0; i < 4; i++) {
        if (i == u_channel_idx) {
            color = current[i];
        }
    }

    // if the intensity of this fragment is 0, don't draw it
    if (color == 0.0) discard;

    gl_FragColor = vec4(vec3(color), 1.0);
}
