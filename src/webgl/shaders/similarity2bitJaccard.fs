#version 300 es

precision mediump float;
precision mediump int;
precision mediump usampler2D;

in vec2 v_texture_position;

uniform vec2 u_mouse_position;
uniform float u_normalization;
uniform sampler2D u_mask;
uniform sampler2D u_spectrumMask;
uniform float u_spectrumMaskWidth;
uniform float u_spectrumMaskHeight;

out vec4 outColor;

const vec4 ONES = vec4(1);
const vec4 ZEROS = vec4(0);

<%=SAMPLER_DEFINITION=%>
<%=CONVERT_UVEC=%>


vec2 compare4channels(uint c, uint r) {
    // Calculate size of intersection I and size of union U for 4 2bit-mass-channels (empty channels are ignored).

    float I = 0.0; // Size of intersection
    float U = 0.0; // Size of union

    // Shift bits in steps of 2 and apply mask 0x3u = 00000011 to extract lowest two bits.
    uint cBits_1_0 = c & 0x3u;          // Ch. 1, current pixel
    uint cBits_3_2 = (c >> 2) & 0x3u;   // Ch. 2, current pixel
    uint cBits_5_4 = (c >> 4) & 0x3u;   // Ch. 3, current pixel
    uint cBits_7_6 = (c >> 6) & 0x3u;   // Ch. 4, current pixel
    uint rBits_1_0 = r & 0x3u;          // Ch. 1, reference pixel
    uint rBits_3_2 = (r >> 2) & 0x3u;   // Ch. 2, reference pixel
    uint rBits_5_4 = (r >> 4) & 0x3u;   // Ch. 3, reference pixel
    uint rBits_7_6 = (r >> 6) & 0x3u;   // Ch. 4, reference pixel

    uvec4 cBits = uvec4(cBits_1_0, cBits_3_2, cBits_5_4, cBits_7_6);
    uvec4 rBits = uvec4(rBits_1_0, rBits_3_2, rBits_5_4, rBits_7_6);

    for (int i = 0; i < 4; i++) {
        if (cBits[i] == 0u && rBits[i] == 0u) {
            // Skip empty channels
            continue;
        }
        U += 1.0;
        if (cBits[i] == rBits[i]) {
            I += 1.0;
        }
    }

    return vec2(I, U);
}

vec2 compare(vec4 current, vec4 reference) {
    uvec4 C = uvec4(current);
    uvec4 R = uvec4(reference);
    vec2 N = vec2(0.0, 0.0);

    // Compare channels 1-4
    N += compare4channels(C.r, R.r);
    // Compare channels 5-8
    N += compare4channels(C.g, R.g);
    // Compare channels 9-12
    N += compare4channels(C.b, R.b);
    // Compare channels 13-16
    N += compare4channels(C.a, R.a);

    return N;
}


void main() {
    // skip masked-out pixels by setting outColor to -1.0.
    vec4 maskPixel = texture(u_mask, v_texture_position);
    if (maskPixel.r < 0.5) {
        outColor = vec4(-1.0);
        return;
    }

    // Jaccard-Index
    float J = 0.0;
    // N[0]: Size of intersection
    // N[1]: Size of union
    vec2 N = vec2(0.0, 0.0);

    // cummulating the squared length of this pixels vector
    float currentLength = 0.0;

    // temporary texture values of current position
    vec4 current;
    // temporary texture values of reference position
    vec4 reference;

    // the index of the current tile
    float tile;

    // the row-major index of the current tile on it's texture
    float index_on_referencer;
    // the column in which the current tile lies on the texture
    float column;
    // the row in which the current tile lies on the texture
    float row;
    // the index of the texture, the current tile is on
    float sampler_index;

    // the 2d coordinates of the current position on the correct texture
    vec2 coords_2d_current;
    // the 2d coordinates of the reference position on the correct texture
    vec2 coords_2d_reference;

    for (int i = 0; i < <%=TILES=%>; i++) {
        tile = float(i);

        index_on_referencer = mod(tile, <%=TILES_PER_TEXTURE=%>);
        column = mod(index_on_referencer, <%=TILE_COLUMNS=%>);
        row = floor(index_on_referencer / <%=TILE_COLUMNS=%>);

        coords_2d_reference = vec2(
            <%=TILE_WIDTH=%> * (column + u_mouse_position.x),
            <%=TILE_HEIGHT=%> * (row + u_mouse_position.y)
        );

        coords_2d_current = vec2(
            <%=TILE_WIDTH=%> * (column + v_texture_position.x),
            // y-flip the texture position because the textures are stored y-flipped.
            <%=TILE_HEIGHT=%> * (row + 1.0 - v_texture_position.y)
        );

        // needed for DYNAMIC_SAMPLER_QUERIES
        sampler_index = floor(tile / <%=TILES_PER_TEXTURE=%>);

        // get rgba of the pixel to compare
        // get rgba of the position of this pixel
        <%=DYNAMIC_SAMPLER_QUERIES
            reference = convertUvec(texture(<%=SAMPLER=%>, coords_2d_reference));
            current = convertUvec(texture(<%=SAMPLER=%>, coords_2d_current));
        =%>

        // spectrum mask
        float maskX = mod(tile, u_spectrumMaskWidth);
        float maskY = floor(tile / u_spectrumMaskWidth);

        vec2 spectrumMaskCoord = vec2(
            (maskX + 0.5) / u_spectrumMaskWidth,
            (maskY + 0.5) / u_spectrumMaskHeight
        );

        vec4 spectrumMaskPixel = texture(u_spectrumMask, spectrumMaskCoord);

        if (spectrumMaskPixel.r < 0.5) {
            reference.r = 0.0;
            current.r = 0.0;
        }
        if (spectrumMaskPixel.g < 0.5) {
            reference.g = 0.0;
            current.g = 0.0;
        }
        if (spectrumMaskPixel.b < 0.5) {
            reference.b = 0.0;
            current.b = 0.0;
        }
        if (spectrumMaskPixel.a < 0.5) {
            reference.a = 0.0;
            current.a = 0.0;
        }

        currentLength += dot(current, current);
        N += compare(current, reference);
    }

    // if the intensities of this fragment are all 0, don't draw it
    if (currentLength == 0.0) {
        outColor = ZEROS;
        return;
    }

    // Jaccard-Index: (size of) intersection N[0] over (size of) union N[1]
    J = N[0] / N[1];

    outColor = vec4(J);
}
