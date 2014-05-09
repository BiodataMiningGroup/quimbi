precision mediump float;

varying vec2 v_texture_position;
uniform sampler2D u_color_map;
// uniform vec2 texture_size; // e.g. vec2(120.0, 50.0)
uniform float u_half_point_size;
// i.e. vec2(1.0, 1.0) / texture_size;
uniform vec2 u_pixel_size;

const vec4 ZEROS = vec4(0.0);

void main() {
    // TODO use fraction, compare it to 'fraction boundaries', should be a lot simpler
    vec2 grid_position = v_texture_position / u_pixel_size;
    vec2 grid_position_min = floor(grid_position) + u_half_point_size;
    if (any(lessThan(grid_position, grid_position_min))) {
        gl_FragColor = ZEROS;
        return;
    }
    vec2 grid_position_max = ceil(grid_position) - u_half_point_size;
    if (any(greaterThan(grid_position, grid_position_max))) {
        gl_FragColor = ZEROS;
        return;
    }
    gl_FragColor = texture2D(u_color_map, v_texture_position);
}
