import * as sharedFcts from './helper/sharedRenderFunctions.js';
/**
 * TODO Comment
 */
export default class RenderChannel {
    /**
     * @param framebuffer
     */
    constructor(framebuffer, intensityHistogram) {
        this._colorMapTextureR = null;
        this.id = 'render-channel';
        this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/render-channel.glsl.frag';
        this._gl = null;
        this._tile = null;
        this._channelMask = null;
        this._regionMaskTexture = null;
        this._channel = 0;

        this._mask = [0, 0, 0, 0];

        this.framebuffer = framebuffer;

        this.width = this.framebuffer.width;
        this.height = this.framebuffer.height;
        this.intensityHistogram = intensityHistogram;
    }

    /**
     * Init Method for glmvilib
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    setUp(gl, program, assets, helpers) {

        helpers.useInternalVertexPositions(program);
        helpers.useInternalTexturePositions(program);
        helpers.useInternalTextures(program);

        this._tile = gl.getUniformLocation(program, 'u_tile');
        this._channelMask = gl.getUniformLocation(program, 'u_channel_mask');

        this.setUpDistanceTexture(gl, assets, helpers);

        this._regionMaskTexture = this.setUpRegionMask(gl, program, assets, helpers);

        this._gl = gl;

        this._colorMapTextureR = helpers.newTexture('colorMapTextureR');
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, 256, 1, 0, gl.RGB, gl.UNSIGNED_BYTE, this.getColorMapValues());
        gl.uniform1i(gl.getUniformLocation(program, 'u_color_map_r'), 1);
    }

    /**
     *
     * @param gl
     * @param assets
     * @param helpers
     */
    setUpDistanceTexture(gl, assets, helpers) {
      sharedFcts.setUpDistanceTexture(gl,assets,helpers, this.width, this.height);
    };

    /**
     *
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    setUpRegionMask (gl, program, assets, helpers) {
      return sharedFcts.setUpRegionMask(gl, program, assets, helpers, this.width, this.height);
    };

    /**
     * @param mask
     */
    updateRegionMask (mask) {
      sharedFcts.updateRegionMask(this._gl, mask, this._regionMaskTexture);
    };

    updateChannel(channel) {
				this._channel = channel;
				this._mask[0] = (this._mask[1] = (this._mask[2] = (this._mask[3] = 0)));
				return this._mask[channel % 4] = 1;
		};


    /**
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    callback(gl, program, assets, helpers) {
      helpers.bindInternalTextures();

      gl.activeTexture(gl.TEXTURE1);
      gl.bindTexture(gl.TEXTURE_2D, this._regionMaskTexture);
      gl.uniform1f(this._tile, Math.floor(this._channel / 4));
      gl.uniform4f(this._channelMask, this._mask[0], this._mask[1], this._mask[2], this._mask[3]);
      gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
    };

    postCallback (gl, program, assets, helpers) {
        this.framebuffer.updateIntensities();
        this.intensityHistogram.updateHistogram();
    };

    /**
     * Holds and returns the colormap. The 3 rgb values of the 256 colors are are written one after another.
     * @returns {Uint8Array}
     */
    getColorMapValues() {
        return new Uint8Array([
            0,0,0,
            0,0,7,
            0,0,15,
            0,0,22,
            0,0,30,
            0,0,38,
            0,0,45,
            0,0,53,
            0,0,61,
            0,0,65,
            0,0,69,
            0,0,74,
            0,0,78,
            0,0,82,
            0,0,87,
            0,0,91,
            1,0,96,
            4,0,100,
            7,0,104,
            10,0,108,
            13,0,113,
            16,0,117,
            19,0,121,
            22,0,125,
            25,0,130,
            28,0,134,
            31,0,138,
            34,0,143,
            37,0,147,
            40,0,151,
            43,0,156,
            46,0,160,
            49,0,165,
            52,0,168,
            55,0,171,
            58,0,175,
            61,0,178,
            64,0,181,
            67,0,185,
            70,0,188,
            73,0,192,
            76,0,195,
            79,0,199,
            82,0,202,
            85,0,206,
            88,0,209,
            91,0,213,
            94,0,216,
            98,0,220,
            101,0,220,
            104,0,221,
            107,0,222,
            110,0,223,
            113,0,224,
            116,0,225,
            119,0,226,
            122,0,227,
            125,0,224,
            128,0,222,
            131,0,220,
            134,0,218,
            137,0,216,
            140,0,214,
            143,0,212,
            146,0,210,
            148,0,206,
            150,0,202,
            152,0,199,
            154,0,195,
            156,0,191,
            158,0,188,
            160,0,184,
            162,0,181,
            163,0,177,
            164,0,173,
            166,0,169,
            167,0,166,
            168,0,162,
            170,0,158,
            171,0,154,
            173,0,151,
            174,0,147,
            175,0,143,
            177,0,140,
            178,0,136,
            179,0,132,
            181,0,129,
            182,0,125,
            184,0,122,
            185,0,118,
            186,0,114,
            188,0,111,
            189,0,107,
            190,0,103,
            192,0,100,
            193,0,96,
            195,0,93,
            196,1,89,
            198,3,85,
            199,5,82,
            201,7,78,
            202,8,74,
            204,10,71,
            205,12,67,
            207,14,64,
            208,16,60,
            209,19,56,
            210,21,53,
            212,24,49,
            213,27,45,
            214,29,42,
            215,32,38,
            217,35,35,
            218,37,31,
            220,40,27,
            221,43,23,
            223,46,20,
            224,48,16,
            226,51,12,
            227,54,8,
            229,57,5,
            230,59,4,
            231,62,3,
            233,65,3,
            234,68,2,
            235,70,1,
            237,73,1,
            238,76,0,
            240,79,0,
            241,81,0,
            243,84,0,
            244,87,0,
            246,90,0,
            247,92,0,
            249,95,0,
            250,98,0,
            252,101,0,
            252,103,0,
            252,105,0,
            253,107,0,
            253,109,0,
            253,111,0,
            254,113,0,
            254,115,0,
            255,117,0,
            255,119,0,
            255,121,0,
            255,123,0,
            255,125,0,
            255,127,0,
            255,129,0,
            255,131,0,
            255,133,0,
            255,134,0,
            255,136,0,
            255,138,0,
            255,140,0,
            255,141,0,
            255,143,0,
            255,145,0,
            255,147,0,
            255,148,0,
            255,150,0,
            255,152,0,
            255,154,0,
            255,155,0,
            255,157,0,
            255,159,0,
            255,161,0,
            255,162,0,
            255,164,0,
            255,166,0,
            255,168,0,
            255,169,0,
            255,171,0,
            255,173,0,
            255,175,0,
            255,176,0,
            255,178,0,
            255,180,0,
            255,182,0,
            255,184,0,
            255,186,0,
            255,188,0,
            255,190,0,
            255,191,0,
            255,193,0,
            255,195,0,
            255,197,0,
            255,199,0,
            255,201,0,
            255,203,0,
            255,205,0,
            255,206,0,
            255,208,0,
            255,210,0,
            255,212,0,
            255,213,0,
            255,215,0,
            255,217,0,
            255,219,0,
            255,220,0,
            255,222,0,
            255,224,0,
            255,226,0,
            255,228,0,
            255,230,0,
            255,232,0,
            255,234,0,
            255,235,4,
            255,237,8,
            255,239,13,
            255,241,17,
            255,242,21,
            255,244,26,
            255,246,30,
            255,248,35,
            255,248,42,
            255,249,50,
            255,250,58,
            255,251,66,
            255,252,74,
            255,253,82,
            255,254,90,
            255,255,98,
            255,255,105,
            255,255,113,
            255,255,121,
            255,255,129,
            255,255,136,
            255,255,144,
            255,255,152,
            255,255,160,
            255,255,167,
            255,255,175,
            255,255,183,
            255,255,191,
            255,255,199,
            255,255,207,
            255,255,215,
            255,255,223,
            255,255,227,
            255,255,231,
            255,255,235,
            255,255,239,
            255,255,243,
            255,255,247,
            255,255,251,
            255,255,255,
            255,255,255,
            255,255,255,
            255,255,255,
            255,255,255,
            255,255,255,
            255,255,255,
            255,255,255,
        ]);
    }
}
