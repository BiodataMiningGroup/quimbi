precision mediump float;

varying vec2 v_texture_position;
uniform sampler2D u_image;

void main() {
    gl_FragColor = texture2D(u_image, v_texture_position);
}
