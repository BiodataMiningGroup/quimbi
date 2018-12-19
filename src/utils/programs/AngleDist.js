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

        // Add helper classes
        this.framebuffer = framebuffer;
        this.intensityHistogram = intensityHistogram;
    }

    /**
     * Sets current mouse position
     * @param mouseX
     * @param mouseY
     */
    updateMouse(mouseX, mouseY) {
        this.mouseX = mouseX;
        this.mouseY = mouseY;
    }

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
    }

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

        let normalization = gl.getUniformLocation(program, 'u_normalization');
        gl.uniform1f(normalization, 1 / this.maxAngleDist);

        assets._mousePosition = gl.getUniformLocation(program, 'u_mouse_position');
        this.setUpDistanceTexture(gl, assets, helpers);
    }

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
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
    }

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
    }

}
