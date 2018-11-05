export default class AngleDist {

    constructor() {
        this.id = 'angle-dist';
        this.vertexShaderUrl = '/shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/angle-dist.glsl.frag';
        this._gl = undefined;
        this._mousePosition = undefined;
        this.maxAngleDist = Math.PI / 2;
    }


    setUp(gl, program, assets, helpers) {
        this._gl = gl;
        let mousePosition = null;
        let channelMaskTexture = null;
        let _regionMaskTexture = null;
        helpers.useInternalVertexPositions(program);
        helpers.useInternalTexturePositions(program);
        helpers.useInternalTextures(program);

        let normalization = gl.getUniformLocation(program, 'u_normalization');
        gl.uniform1f(normalization, 1 / this.maxAngleDist);

        this._mousePosition = gl.getUniformLocation(program, 'u_mouse_position');

        //setUpDistanceTexture(gl, assets, helpers);

        //_channelMaskTexture = setUpChannelMask(gl, program, assets, helpers);
        //_regionMaskTexture = setUpRegionMask(gl, program, assets, helpers);
    }

    callback(gl, program, assets, helpers) {
        gl.uniform2f(this._mousePosition, mouse.position.x, 1 - mouse.position.y);
        helpers.bindInternalTextures();
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, _channelMaskTexture);
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, _regionMaskTexture);
        gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
    }

    updateChannelMask(mask) {
        updateChannelMask(this._gl, mask, _channelMaskTexture);
    }

    updateRegionMask(mask) {
        updateRegionMask(this._gl, mask, _regionMaskTexture);
    }

}
