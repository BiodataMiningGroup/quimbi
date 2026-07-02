#version 300 es

precision mediump float;
precision mediump int;
precision mediump usampler2D;

in vec2 v_texture_position;

uniform vec4 u_channel_mask;
uniform sampler2D u_mask;

out vec4 outColor;

const vec4 ONES = vec4(1);

uniform sampler2D u_texture;

void main() {

    vec4 maskColor = texture(u_mask, v_texture_position);
    if (maskColor.r < 0.5) {
        discard;
    }

    vec4 colors = texture(u_texture, vec2(v_texture_position.x, 1.0 - v_texture_position.y));
    float channel_color = dot(colors * u_channel_mask, ONES);

    outColor = vec4(channel_color);
}
