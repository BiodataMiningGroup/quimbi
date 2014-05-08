attribute vec2 a_vertex_position;
attribute vec2 a_texture_position;
varying vec2 v_texture_position;

const vec2 texture_size = vec2(120.0, 50.0);
const vec2 pixel_size = vec2(2.0, 2.0) / texture_size;

void main() {


    // float move = 0.0;
    // vec2 grid_position = mod(floor((a_vertex_position + 1.0) / pixel_size), 2.0);

    // //if (grid_position.x != 0.0 || grid_position.y != 0.0) {
    // if (grid_position.x > 0.0) {// || grid_position.y != 0.0) {
    //     move = 10.0;
    // } else {
    //     move = -10.0;
    // }

    // gl_Position = vec4(a_vertex_position + pixel_size * move, 0, 1);


    // gl_Position = vec4((a_vertex_position + 1.0) * 2.0 - 1.0, 0, 1);
    gl_Position = vec4(a_vertex_position, 0, 1);
    v_texture_position = a_texture_position;

}
