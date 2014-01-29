precision mediump float;

varying vec2 v_texture_position;

<%=TEXTURE_3D=%>

void main() {
	gl_FragColor = glmvilib_texture3D(vec3(v_texture_position, 0.0));
}