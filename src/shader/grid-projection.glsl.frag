precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_rgb;
uniform sampler2D u_color_map_r;
uniform sampler2D u_color_map_g;
uniform sampler2D u_color_map_b;

uniform vec3 u_color_mask;
const float width = 120.0;
const float height = 50.0;
const vec2 texture_size = vec2(120.0, 50.0);
const vec2 pixel_size = vec2(1.0, 1.0) / texture_size;

void main() {

    // vec2 render_test = mod(v_texture_position, 0.1);
    // if (render_test.x + render_test.y != 0.0) {
    //     discard;
    // }

    vec2 grid_position = mod(floor(v_texture_position / pixel_size), 2.0);
    if (grid_position.x == 0.0 || grid_position.y == 0.0) discard;

    // if (v_texture_position.x > 0.5 && v_texture_position.x < 0.505) discard;


    vec4 color = texture2D(u_rgb, v_texture_position);
    vec3 r = u_color_mask.r * texture2D(u_color_map_r, vec2(color.r, 0.5)).rgb;
    // vec3 g = u_color_mask.g * texture2D(u_color_map_g, vec2(color.g, 0.5)).rgb;
    // vec3 b = u_color_mask.b * texture2D(u_color_map_b, vec2(color.b, 0.5)).rgb;
    gl_FragColor = vec4(r /*+ g + b*/, 1.0);
}
