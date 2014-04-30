precision mediump float;

varying vec3 v_vertex_color;

uniform sampler2D u_color_map_r;
uniform sampler2D u_color_map_g;
uniform sampler2D u_color_map_b;

void main() {
    vec3 r = texture2D(u_color_map_r, vec2(v_vertex_color.r, 0.5)).rgb;
    vec3 g = texture2D(u_color_map_g, vec2(v_vertex_color.g, 0.5)).rgb;
    vec3 b = texture2D(u_color_map_b, vec2(v_vertex_color.b, 0.5)).rgb;
    gl_FragColor = vec4(r + g + b, 1.0);
}