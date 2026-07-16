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

uint compare4Channels(uint c, uint r) {
    // Calculate manhattan distance for 4 2bit-mass-channels.

    // Shift bits in steps of 2 and apply mask 0x3u = 00000011 to extract lowest two bits.
    uint cBits_1_0 = c & 0x3u;          // Ch. 1, current pixel
    uint cBits_3_2 = (c >> 2) & 0x3u;   // Ch. 2, current pixel
    uint cBits_5_4 = (c >> 4) & 0x3u;   // Ch. 3, current pixel
    uint cBits_7_6 = (c >> 6) & 0x3u;   // Ch. 4, current pixel
    uint rBits_1_0 = r & 0x3u;          // Ch. 1, reference pixel
    uint rBits_3_2 = (r >> 2) & 0x3u;   // Ch. 2, reference pixel
    uint rBits_5_4 = (r >> 4) & 0x3u;   // Ch. 3, reference pixel
    uint rBits_7_6 = (r >> 6) & 0x3u;   // Ch. 4, reference pixel

    int dist = 0;
    dist += abs(int(cBits_1_0) - int(rBits_1_0)); // Compare channel 1
    dist += abs(int(cBits_3_2) - int(rBits_3_2)); // Compare channel 2
    dist += abs(int(cBits_5_4) - int(rBits_5_4)); // Compare channel 3
    dist += abs(int(cBits_7_6) - int(rBits_7_6)); // Compare channel 4

    return uint(dist);
}

uint manhattanDistance(vec4 current, vec4 reference) {
    uvec4 C = uvec4(current);
    uvec4 R = uvec4(reference);

    uint dist = 0u;
    // Compare channels 1-4
    dist += compare4Channels(C.r, R.r);
    // Compare channels 5-8
    dist += compare4Channels(C.g, R.g);
    // Compare channels 9-12
    dist += compare4Channels(C.b, R.b);
    // Compare channels 13-16
    dist += compare4Channels(C.a, R.a);

    return dist;
}

void main() {
    // skip masked-out pixels by setting outColor to -1.0.
    vec4 maskPixel = texture(u_mask, v_texture_position);
    if (maskPixel.r < 0.5) {
        outColor = vec4(-1.0);
        return;
    }
    // Manhattan-Distance
    float dist = 0.0;

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
        dist += float(manhattanDistance(current, reference));
    }

    // if the intensities of this fragment are all 0, don't draw it
    if (currentLength == 0.0) {
        outColor = ZEROS;
        return;
    }

    // Normalize distance to value in [0,1].
    dist = dist / u_normalization;

    // Invert distance because a lower distance should signify a higher similarity.
    dist = 1.0 - dist;

    outColor = vec4(dist);
}
