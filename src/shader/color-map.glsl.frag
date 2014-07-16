precision mediump float;

#define M_PI 3.1415926535897932384626433832795

varying vec2 v_texture_position;

uniform sampler2D u_rgb;
uniform sampler2D u_color_map_r;
uniform sampler2D u_color_map_g;
uniform sampler2D u_color_map_b;

uniform vec3 u_color_mask;

const vec3 ONES = vec3(1);

const vec3 BYTE_TO_LCH = vec3(100, 100, 360);

const float ref_X = 95.047;
const float ref_Y = 100.0;
const float ref_Z = 108.883;

const float XYZ_compare = 0.008856;
const float RGB_compare = 0.0031308;

// adapted from colorjizz (https://code.google.com/p/colorjizz/)
vec3 convert_lch_to_rgb(vec3 color) {
	// convert LCh to Lab
	float h_rad = color.b * (M_PI / 180.0);
	float var_L = color.r;
	float var_a = cos(h_rad) * color.g;
	float var_b = sin(h_rad) * color.g;

	// convert Lab to XYZ
	float var_Y = (var_L + 16.0) / 116.0;
	float var_X = var_a / 500.0 + var_Y;
	float var_Z = var_Y - var_b / 200.0;

	float tmp = var_Y * var_Y * var_Y;
	var_Y = (tmp > XYZ_compare) ? tmp : (var_Y - 16.0 / 116.0) / 7.787;

	tmp = var_X * var_X * var_X;
	var_X = (tmp > XYZ_compare) ? tmp : (var_X - 16.0 / 116.0) / 7.787;

	tmp = var_Z * var_Z * var_Z;
	var_Z = (tmp > XYZ_compare) ? tmp : (var_Z - 16.0 / 116.0) / 7.787;

	// X = ref_X * var_X
	var_X = ref_X * var_X / 100.0;
	// Y = ref_Y * var_Y
	var_Y = ref_Y * var_Y / 100.0;
	// Z = ref_Z * var_Z
	var_Z = ref_Z * var_Z / 100.0;

	// convert XYZ to RGB
	float var_R = var_X * 3.2406 - var_Y * 1.5372 - var_Z * 0.4986;
	float var_G = var_Y * 1.8758 + var_Z * 0.0415 - var_X * 0.9689;
	float var_B = var_X * 0.0557 - var_Y * 0.2040 + var_Z * 1.0570;

	var_R = (var_R > RGB_compare)
		? 1.055 * pow(var_R, 1.0/2.4) - 0.055
		: 12.92 * var_R;
	var_G = (var_G > RGB_compare)
		? 1.055 * pow(var_G, 1.0/2.4) - 0.055
		: 12.92 * var_G;
	var_B = (var_B > RGB_compare)
		? 1.055 * pow(var_B, 1.0/2.4) - 0.055
		: 12.92 * var_B;

	return vec3(var_R, var_G, var_B);
}

void main() {
	vec4 intensities = texture2D(u_rgb, v_texture_position);
	float weight = float(dot(u_color_mask, ONES));

	vec3 a = u_color_mask.r *
		texture2D(u_color_map_r, vec2(intensities.r, 0.5)).rgb;
	vec3 b = u_color_mask.g *
		texture2D(u_color_map_g, vec2(intensities.g, 0.5)).rgb;
	vec3 c = u_color_mask.b *
		texture2D(u_color_map_b, vec2(intensities.b, 0.5)).rgb;

	vec3 mixed_colors = vec3(
		(a.r + b.r + c.r) / weight,
		// intensities.r * a.r + intensities.g * b.r + intensities.b * c.r,
		(a.g + b.g + c.g) / weight,
		// intensities.r * a.g + intensities.g * b.g + intensities.b * c.g,
		// (a.g + b.g + c.g) / float(dot(u_color_mask, ONES))
		intensities.r * a.b + intensities.g * b.b + intensities.b * c.b
	);

	// mixed_colors /= float(dot(u_color_mask, ONES));

	// mixed_colors.g = 1.0;

	mixed_colors *= BYTE_TO_LCH;

	gl_FragColor = vec4(convert_lch_to_rgb(mixed_colors), 1.0);
}