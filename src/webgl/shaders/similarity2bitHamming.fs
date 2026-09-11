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

// Lookup table for number of set bits, since WebGL does not support bitCount.
uint BIT_COUNT[256] = uint[256](
    0u, 1u, 1u, 2u, 1u, 2u, 2u, 3u, 1u, 2u, 2u, 3u, 2u, 3u, 3u, 4u,
    1u, 2u, 2u, 3u, 2u, 3u, 3u, 4u, 2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u,
    1u, 2u, 2u, 3u, 2u, 3u, 3u, 4u, 2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u,
    2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u, 3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u,
    1u, 2u, 2u, 3u, 2u, 3u, 3u, 4u, 2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u,
    2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u, 3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u,
    2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u, 3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u,
    3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u, 4u, 5u, 5u, 6u, 5u, 6u, 6u, 7u,
    1u, 2u, 2u, 3u, 2u, 3u, 3u, 4u, 2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u,
    2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u, 3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u,
    2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u, 3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u,
    3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u, 4u, 5u, 5u, 6u, 5u, 6u, 6u, 7u,
    2u, 3u, 3u, 4u, 3u, 4u, 4u, 5u, 3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u,
    3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u, 4u, 5u, 5u, 6u, 5u, 6u, 6u, 7u,
    3u, 4u, 4u, 5u, 4u, 5u, 5u, 6u, 4u, 5u, 5u, 6u, 5u, 6u, 6u, 7u,
    4u, 5u, 5u, 6u, 5u, 6u, 6u, 7u, 5u, 6u, 6u, 7u, 6u, 7u, 7u, 8u
);

uint xor2bit(uint a, uint b) {
    // Apply XOR to groups of 2 bits. A 2bit-group encodes one mass channel.

    // 1. Apply XOR to both values.
    // A 2bit-group that differs will result in a 2bit-group of either 01,10,11 after the XOR.
    uint x = a ^ b;
    // 2. Shift the resulting bit-pattern one position to the right, then OR the bit-pattern with its shifted version.
    // The bit-shift to the right produces a bit-pattern where the higher bit in a group is now at the position of
    // the lower bit. The resulting bit-pattern now looks like this (after the OR):
    // (x7|0) (x6|x7) (x5|x6) (x4|x5) (x3|x4) (x2|x3) (x1|x2) (x0|x1)
    x |= x >> 1;
    // 3. Apply the mask 0x55555555 = ...01010101. The resulting bit-pattern now looks like this:
    // 0 (x6|x7) 0 (x4|x5) 0 (x2|x3) 0 (x0|x1)
    x &= 0x55555555u;
    // In the final bit-pattern, in every group of 2 bits, the lower bit is now either 0 or 1.
    // It is 1 if and only if the original 2bit-groups where different, because in this case either the lower or the
    // higher bit in the group where different (=> higher bit = 1 or lower bit = 1 after the XOR).

    // => Each differing 2bit-group results in a (01)-group, each identical group in a (00)-group.
    // The number of 1's in the final bit-pattern can be counted, which equals the number of differing 2bit-groups.

    return x;
}

uint hammingDistance(vec4 current, vec4 reference) {
    uvec4 C = uvec4(current);
    uvec4 R = uvec4(reference);

    return BIT_COUNT[xor2bit(C.r, R.r)] +
           BIT_COUNT[xor2bit(C.g, R.g)] +
           BIT_COUNT[xor2bit(C.b, R.b)] +
           BIT_COUNT[xor2bit(C.a, R.a)];
}

void main() {
    // skip masked-out pixels by setting outColor to -1.0.
    vec4 maskPixel = texture(u_mask, v_texture_position);
    if (maskPixel.r < 0.5) {
        outColor = vec4(-1.0);
        return;
    }
    // Hamming-Distance
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
        dist += float(hammingDistance(current, reference));
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
