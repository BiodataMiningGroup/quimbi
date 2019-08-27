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
    constructor(framebuffer, intensityHistogram, canvasWidth, canvasHeight) {
        this.id = 'angle-dist';
        this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/angle-dist.glsl.frag';
        this.maxAngleDist = Math.PI / 2;
        this.mouseX = 0;
        this.mouseY = 0;
        this.width = canvasWidth;
        this.height = canvasHeight;
        this._regionMaskTexture = null;
        this._gl = null;
        // Add helper classes
        this.framebuffer = framebuffer;
        this.intensityHistogram = intensityHistogram;
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
        if(typeof(assets.framebuffers.distances) === 'undefined') {
            assets.framebuffers.distances = gl.createFramebuffer();
        }
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
        let texture = helpers.newTexture('distanceTexture');
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
        gl.bindTexture(gl.TEXTURE_2D, null);
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    };

    setUpRegionMask (gl, program, assets, helpers) {
    		let regionMaskTexture = null;
    		gl.uniform1i(gl.getUniformLocation(program, 'u_region_mask'), 1);
    		// check if texture already exists
    		if (!(regionMaskTexture = assets.textures.regionMaskTexture)) {
    			regionMaskTexture = helpers.newTexture('regionMaskTexture');
    			// same dimensions as distance texture
    			gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA,
    				this.width, this.height,
    				0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    		}
        return regionMaskTexture;
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

    updateRegionMask (mask) {
  		this._gl.activeTexture(this._gl.TEXTURE1);
  		this._gl.bindTexture(this._gl.TEXTURE_2D, this._regionMaskTexture);
  		this._gl.texImage2D(this._gl.TEXTURE_2D, 0, this._gl.RGBA, this._gl.RGBA, this._gl.UNSIGNED_BYTE, mask);
        this._gl.bindTexture(this._gl.TEXTURE_2D, null);
	};
}
