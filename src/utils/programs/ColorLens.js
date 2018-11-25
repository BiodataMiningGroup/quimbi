export default class ColorLens {

    constructor(intensityHistogram, width, height) {
        this.id = 'color-lens';
        this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/color-lens.glsl.frag';
        this.width = width;
        this.height = height;
        this._channelBoundsLocation = null;
        this.intensityHistogram = intensityHistogram;
        this.texture = null;
        this.rgbtexture = null;
        this._activeRgbTexture = null;
    }

    setUp(gl, program, assets, helpers) {
        helpers.useInternalVertexPositions(program);
        helpers.useInternalTexturePositions(program);
        // Todo ?!
        this.rgbtexture = helpers.newTexture('rgbTexture0');
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);

        assets.framebuffers.rgbColorLens = gl.createFramebuffer();
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.rgbColorLens);
        this.texture = helpers.newTexture('rgbColorLensTexture');
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.texture, 0);
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        let rgb = gl.getUniformLocation(program, 'u_rgb');
        gl.uniform1i(rgb, 0);

        this._channelBoundsLocation = gl.getUniformLocation(program, 'u_channel_bounds_r');
    }

    callback(gl, program, assets, helpers) {
        gl.activeTexture(gl.TEXTURE0);
        //Todo ??
        gl.bindTexture(gl.TEXTURE_2D, assets.textures.distanceTexture);


        let _channelBounds = this.intensityHistogram.bounds;
        gl.uniform2f(this._channelBoundsLocation, _channelBounds[0], 1 / ((_channelBounds[1] || 1) - _channelBounds[0]));

        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.rgbColorLens);
    }

}