precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_rgb;
uniform sampler2D u_color_map_r;
uniform sampler2D u_color_map_g;
uniform sampler2D u_color_map_b;

uniform vec3 u_color_mask;

void main() {
    vec4 color = texture2D(u_rgb, v_texture_position);
    vec3 r = u_color_mask.r * texture2D(u_color_map_r, vec2(color.r, 0.5)).rgb;
    vec3 g = u_color_mask.g * texture2D(u_color_map_g, vec2(color.g, 0.5)).rgb;
    vec3 b = u_color_mask.b * texture2D(u_color_map_b, vec2(color.b, 0.5)).rgb;
    gl_FragColor = vec4(r + g + b, 1.0);
}