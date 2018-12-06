export default class SelectionInfo {
    constructor(framebuffer, textureDimension, width, height) {
        this.framebuffer = framebuffer;
        this.mousePosition = null;
        this.id = 'selection-info';
        this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/selection-info.glsl.frag';

        this.width = width;
        this.height = height;

        this.textureDimension = textureDimension;

        this.mouseX = null;
        this.mouseY = null;
    }

    updateMouse(mouseX, mouseY) {
        this.mouseX = mouseX;
        this.mouseY = mouseY;
    }

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


    callback (gl, program, assets, helpers) {
        gl.viewport(0, 0, this.textureDimension, this.textureDimension);
        gl.uniform2f(this.mousePosition, this.mouseX, 1 - this.mouseY);
        helpers.bindInternalTextures();
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.selection);
    }

    postCallback (gl, program, assets, helpers) {
        gl.viewport(0, 0, this.width, this.height);
    }


}