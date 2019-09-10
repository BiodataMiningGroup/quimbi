import * as sharedFcts from './helper/sharedRenderFunctions.js';
/**
 * Shader Program to calculate the distance map for a given pixel with the angledistance
 */
export default class RGBSelection {

    /**
     *
     * @param framebuffer
     * @param intensityHistogram
     * @param canvasWidth
     * @param canvasHeight
     */
    constructor(framebuffer, intensityHistogram) {
        this._colorMask = [0, 0, 0];
			  this._colorMaskLocation = null;
			  this._activeRgbTextureIndex = 0;

        this.id = 'rgb-selection';
        this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/angle-dist.glsl.frag';

        // Add helper classes
        this.intensityHistogram = intensityHistogram;
        this.framebuffer = framebuffer;

        this.width = this.framebuffer.width;
        this.height = this.framebuffer.height;
        this._gl = null;
    };

    /**
     *
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    setUp(gl, program, assets, helpers) {
        helpers.useInternalVertexPositions(program);
        helpers.useInternalTexturePositions(program);

        let distances = gl.getUniformLocation(program, 'u_distances');
				gl.uniform1i(distances, 0);
        assets.framebuffers.rgb = gl.createFramebuffer();
        let texture = helpers.newTexture('rgbTexture0');
				gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
				this._activeRgbTexture = texture;

        texture = helpers.newTexture('rgbTexture1');

        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);

				const rgb = gl.getUniformLocation(program, 'u_rgb');
				gl.uniform1i(rgb, 1);

				this._colorMaskLocation = gl.getUniformLocation(program, 'u_color_mask');
    };

    /**
     *
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    callback(gl, program, assets, helpers) {
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, assets.textures.distanceTexture);
      gl.activeTexture(gl.TEXTURE1);
      gl.bindTexture(gl.TEXTURE_2D, this._activeRgbTexture);

      // Now swap the active texture to have one as source, and the other as render
      // target.
      this._activeRgbTextureIndex = (this._activeRgbTextureIndex + 1) % 2;
      this._activeRgbTexture = assets.textures['rgbTexture' + this._activeRgbTextureIndex];

      gl.uniform3f(this._colorMaskLocation, this._colorMask[0], this._colorMask[1], this._colorMask[2]);
      gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.rgb);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this._activeRgbTexture, 0);
    };

    /**
     *
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    postCallback (gl, program, assets, helpers) {
        this.framebuffer.updateIntensities();
    };

    updateColorMask(mask) {
				this._colorMask[0] = mask[0];
				this._colorMask[1] = mask[1];
				this._colorMask[2] = mask[2];
			};
}
