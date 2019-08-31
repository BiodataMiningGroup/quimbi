/**
 * Shader Program to get the mass spectrum for selected pixel
 */
export default class SelectionInfo {
    /**
     * @param framebuffer
     * @param textureDimension
     * @param width
     * @param height
     */
    constructor(framebuffer, textureDimension) {
        this.framebuffer = framebuffer;
        this.mousePosition = null;
        this.id = 'selection-info';
        this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/selection-info.glsl.frag';

        this.width = this.framebuffer.width;
        this.height = this.framebuffer.height;

        this.textureDimension = textureDimension;

        this.mouseX = null;
        this.mouseY = null;
    }

    /**
     * Set current mouse position
     * @param mouseX
     * @param mouseY
     */
    updateMouse(mouseX, mouseY) {
        this.mouseX = mouseX;
        this.mouseY = mouseY;
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

        this.mousePosition = gl.getUniformLocation(program, 'u_mouse_position');

        let dim = gl.getUniformLocation(program, 'u_texture_dimension');
        gl.uniform1f(dim, this.textureDimension);

        assets.framebuffers.selection = gl.createFramebuffer();
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.selection);
        let texture = helpers.newTexture('selectionTexture');
        // Todo input.getChannelTextureDimension ??
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.textureDimension, this.textureDimension, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    }

    /**
     *
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    callback (gl, program, assets, helpers) {
        gl.viewport(0, 0, this.textureDimension, this.textureDimension);
        gl.uniform2f(this.mousePosition, this.mouseX, this.mouseY);
        helpers.bindInternalTextures();
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.selection);
    }

    /**
     *
     * @param gl
     * @param program
     * @param assets
     * @param helpers
     */
    postCallback (gl, program, assets, helpers) {
        gl.viewport(0, 0, this.width, this.height);
    }


}
