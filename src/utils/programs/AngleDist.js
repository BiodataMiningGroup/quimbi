import * as sharedFcts from './helper/sharedRenderFunctions.js';
/**
 * Shader Program to calculate the distance map for a given pixel with the angledistance
 */
export default class AngleDist {

    /**
     *
     * @param framebuffer
     * @param intensityHistogram
     * @param canvasWidth
     * @param canvasHeight
     */
    constructor(framebuffer, intensityHistogram) {
        this.id = 'angle-dist';
        this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/angle-dist.glsl.frag';
        this.maxAngleDist = Math.PI / 2;
        this.mouseX = 0;
        this.mouseY = 0;
        // Add helper classes
        this.intensityHistogram = intensityHistogram;
        this.framebuffer = framebuffer;

        this.width = this.framebuffer.width;
        this.height = this.framebuffer.height;
        this.channelTextureDimension = this.framebuffer.selectionInfoTextureDimension;
        this._regionMaskTexture = null;
        this._channelMaskTexture = null;
        this._gl = null;
    };

    /**
     * Sets current mouse position
     * @param mouseX
     * @param mouseY
     */
    updateMouse(mouseX, mouseY) {
        this.mouseX = mouseX;
        this.mouseY = mouseY;
    };

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
      return sharedFcts.setUpRegionMask (gl, program, assets, helpers, this.width, this.height);
    };

    /**
     * @param mask
     */
    updateRegionMask (mask) {
      sharedFcts.updateRegionMask(this._gl, mask, this._regionMaskTexture);
    };

    /**
     *
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    setUpChannelMask(gl, program, assets, helpers){
      return sharedFcts.setUpChannelMask(gl, program, assets, helpers, this.channelTextureDimension);
    };

    updateChannelMask(mask){
      sharedFcts.updateChannelMask(this._gl, mask, this._channelMaskTexture, this.channelTextureDimension);
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
        helpers.useInternalTextures(program);

        this._gl = gl;

        let normalization = gl.getUniformLocation(program, 'u_normalization');
        gl.uniform1f(normalization, 1 / this.maxAngleDist);

        assets._mousePosition = gl.getUniformLocation(program, 'u_mouse_position');
        this.setUpDistanceTexture(gl, assets, helpers);


        this._regionMaskTexture = this.setUpRegionMask(gl, program, assets, helpers);
        this._channelMaskTexture = this.setUpChannelMask(gl, program, assets, helpers);
    };

    /**
     *
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    callback(gl, program, assets, helpers) {
        gl.uniform2f(assets._mousePosition, this.mouseX, this.mouseY);
        helpers.bindInternalTextures();
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, this._regionMaskTexture);
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
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
        this.intensityHistogram.updateHistogram();
    };
}
