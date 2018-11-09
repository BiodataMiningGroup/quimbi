export default class AngleDist {

    constructor() {
        this.id = 'angle-dist';
        this.vertexShaderUrl = '/shader/display-rectangle.glsl.vert';
        this.fragmentShaderUrl = 'shader/angle-dist.glsl.frag';
        this._gl = undefined;
        this._mousePosition = undefined;
        this.maxAngleDist = Math.PI / 2;
        this.assets = {};

        this._channelMaskTexture = null;
        this._regionMaskTexture = null;
    }

    updateMouse(mouseX, mouseY) {
        this.assets.mouseX = mouseX;
        this.assets.mouseY = mouseY;
    }


    setUp(gl, program, assets, helpers) {
        this._gl = gl;
        this.assets = assets;
        helpers.useInternalVertexPositions(program);
        helpers.useInternalTexturePositions(program);
        helpers.useInternalTextures(program);

        let normalization = gl.getUniformLocation(program, 'u_normalization');
        gl.uniform1f(normalization, 1 / this.maxAngleDist);

        this.assets._mousePosition = gl.getUniformLocation(program, 'u_mouse_position');

        // Todo do i need this right now?
        //this._channelMaskTexture = this.setUpChannelMask(gl, program, assets, helpers);
        // Todo soll raus
        //this._regionMaskTexture = setUpRegionMask(gl, program, assets, helpers);
    }

    callback(gl, program, assets, helpers) {
        //console.log(this);
        gl.uniform2f(assets._mousePosition, assets.mouseX, assets.mouseY);
        helpers.bindInternalTextures();
        //gl.activeTexture(gl.TEXTURE0);
        //Todo where does _channelMaskTexture come from, do i need it right now?
        //gl.bindTexture(gl.TEXTURE_2D, _channelMaskTexture);
        //gl.activeTexture(gl.TEXTURE1);
        // Todo Call setUpDistanceTexture and:
        //gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    }
/*
    updateChannelMask(mask) {
        updateChannelMask(this._gl, mask, this._channelMaskTexture);
    }

    updateRegionMask(mask) {
        updateRegionMask(this._gl, mask, this._regionMaskTexture);
    }
*/
    // Todo implementation correct? Needed right now?
    /*
    setUpChannelMask(gl, program, assets, helpers) {
        let channelMaskTexture;
        gl.uniform1i(gl.getUniformLocation(program, 'u_channel_mask'), 0);

        // Todo where does input.getchanneltexture... come from?
        //gl.uniform1f(gl.getUniformLocation(program, 'u_channel_mask_dimension'), input.getChannelTextureDimension());
        //gl.uniform1f(gl.getUniformLocation(program, 'u_inv_channel_mask_dimension'), 1 / input.getChannelTextureDimension());
        //check if texture already exists
        if(!assets.textures.channelMaskTexture) {
            channelMaskTexture = assets.textures.channelMaskTexture;
        } else {
            channelMaskTexture = helpers.newTexture('channelMaskTexture');
        }
        // Todo where does input.getchanneltexture... come from?
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, input.getChannelTextureDimension(),
            input.getChannelTextureDimension(), 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        return channelMaskTexture;
    }
    */

}
