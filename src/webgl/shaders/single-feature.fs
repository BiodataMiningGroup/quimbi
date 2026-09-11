#version 300 es

precision mediump float;
precision mediump int;
precision mediump usampler2D;

in vec2 v_texture_position;

uniform sampler2D u_mask;
uniform sampler2D u_texture;

out vec4 outColor;

void main() {

    vec4 maskColor = texture(u_mask, v_texture_position);
    if (maskColor.r < 0.5) {
        discard;
    }

    float color = texture(u_texture, vec2(v_texture_position.x, 1.0 - v_texture_position.y)).r;
    outColor = vec4(color);
}
