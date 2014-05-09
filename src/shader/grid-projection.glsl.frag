precision mediump float;

varying vec2 v_texture_position;

uniform sampler2D u_rgb;
uniform sampler2D u_color_map_r;
uniform sampler2D u_color_map_g;
uniform sampler2D u_color_map_b;

uniform vec3 u_color_mask;
// uniform vec2 texture_size; // e.g. vec2(120.0, 50.0)
uniform float u_render_scale; // how much bigger than the data dimensions is the canvas? >= 1.0
uniform float u_space_fill_percent; // 0.0 .. 1.0 meaningfule are only steps in pixel size
uniform vec2 u_pixel_size; // i.e. vec2(1.0, 1.0) / texture_size;

const vec4 ZEROS = vec4(0.0);


// vec4 tex2DBiLinear( sampler2D textureSampler_i, vec2 texCoord_i )
// {
//     vec4 p0q0 = texture2D(textureSampler_i, texCoord_i);
//     vec4 p1q0 = texture2D(textureSampler_i, texCoord_i + vec2(pixel_size.x, 0));

//     vec4 p0q1 = texture2D(textureSampler_i, texCoord_i + vec2(0, pixel_size.y));
//     vec4 p1q1 = texture2D(textureSampler_i, texCoord_i + vec2(pixel_size.x , pixel_size.y));

//     float a = fract( texCoord_i.x * texture_size.x ); // Get Interpolation factor for X direction.
//                     // Fraction near to valid data.

//     vec4 pInterp_q0 = mix( p0q0, p1q0, a ); // Interpolates top row in X direction.
//     vec4 pInterp_q1 = mix( p0q1, p1q1, a ); // Interpolates bottom row in X direction.

//     float b = fract( texCoord_i.y * texture_size.y );// Get Interpolation factor for Y direction.
//     return mix( pInterp_q0, pInterp_q1, b ); // Interpolate in Y direction.
// }

void main() {

    // vec2 render_test = mod(v_texture_position, 0.1);
    // if (render_test.x + render_test.y != 0.0) {
    //     discard;
    // }

    // vec2 grid_position = mod(floor(v_texture_position / u_pixel_size), 2.0);
    // if (grid_position.x == 0.0 || grid_position.y == 0.0) discard;

    // ich habe gerade 240*100 output pixel aber nur 120*50 textur pixel
    // also 4px pro Punkt, 2 pro zeile * 2 pro spalte
    // ich möchte nur den Punkt links oben malen
    // Wie berechne ich dessen Koordinaten?
    // check if coord between grid coord and grid coord + treshold

    // TODO use fraction
    vec2 grid_position = v_texture_position / u_pixel_size;
    float point_size = (1.0 - 1.0 / u_render_scale * (u_space_fill_percent * u_render_scale)) / 2.0;
    vec2 grid_position_min = floor(grid_position) + point_size;
    vec2 grid_position_max = ceil(grid_position) - point_size;

    if (any(lessThan(grid_position, grid_position_min)) || any(greaterThan(grid_position, grid_position_max))) {
        gl_FragColor = ZEROS;
        return;
    }

    // vec2 grid_position = mod(floor(v_texture_position / u_pixel_size), 2.0);
    // if (grid_position.x != 0.0 || grid_position.y != 0.0) discard;

    // if (v_texture_position.x > 0.5 && v_texture_position.x < 0.505) discard;


    vec4 color = texture2D(u_rgb, v_texture_position); //tex2DBiLinear(u_rgb, v_texture_position); //texture2D(u_rgb, v_texture_position);
    vec3 r = u_color_mask.r * texture2D(u_color_map_r, vec2(color.r, 0.5)).rgb;
    vec3 g = u_color_mask.g * texture2D(u_color_map_g, vec2(color.g, 0.5)).rgb;
    vec3 b = u_color_mask.b * texture2D(u_color_map_b, vec2(color.b, 0.5)).rgb;
    gl_FragColor = vec4(r + g + b, 1.0);
}
