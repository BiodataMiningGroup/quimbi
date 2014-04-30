attribute vec2 a_vertex_position;
attribute vec3 a_vertex_color;

varying vec3 v_vertex_color;

void main() {
	gl_Position = vec4(a_vertex_position, 0, 1);
	v_vertex_color = a_vertex_color;
}