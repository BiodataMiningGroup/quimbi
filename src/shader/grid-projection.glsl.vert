attribute vec2 a_vertex_position;
attribute vec2 a_texture_position;
varying vec2 v_texture_position;

void main() {
    gl_Position = vec4(a_vertex_position, 0, 1);

    v_texture_position = a_texture_position;

    if (a_vertex_position.x > -1.1 && a_vertex_position.y > -1.1) {
        v_texture_position = a_texture_position;
    } else {
        v_texture_position = vec2(0.0);
    }
}
