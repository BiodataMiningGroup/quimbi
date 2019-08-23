
export default class RenderMeanRanges {

		constructor(framebuffer) {
			this._channelMaskTexture = null;
			this._regionMaskTexture = null;
			// pointer to the uniform
			this._invActiveChannels = null;
			// number of active channels of the current channel mask
			this._activeChannels = 0;
			this.id = 'render-mean-ranges';
			this.vertexShaderUrl = 'shader/display-rectangle.glsl.vert';
			this.fragmentShaderUrl = 'shader/render-mean-ranges.glsl.frag';

			this._gl = null;

			this.framebuffer = framebuffer
		}

		setUp(gl, program, assets, helpers) {

				this._gl = gl;

				helpers.useInternalVertexPositions(program);
				helpers.useInternalTexturePositions(program);
				helpers.useInternalTextures(program);

			  this._invActiveChannels = gl.getUniformLocation(program, 'u_inv_active_channels');

				this.setUpDistanceTexture(gl, assets, helpers);

				//_channelMaskTexture = setUpChannelMask(gl, program, assets, helpers);
				this._regionMaskTexture = this.setUpRegionMask(gl, program, assets, helpers);
			};

			callback(gl, program, assets, helpers) {
				gl.uniform1f(this._invActiveChannels, 1 / (this._activeChannels || -1));
				helpers.bindInternalTextures();
				gl.activeTexture(gl.TEXTURE0);
				gl.bindTexture(gl.TEXTURE_2D, _channelMaskTexture);
				gl.activeTexture(gl.TEXTURE1);
				gl.bindTexture(gl.TEXTURE_2D, this._regionMaskTexture);
				gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
			};

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


			updateChannelMask(mask, activeChannels) {
				this._activeChannels = activeChannels;
				return updateChannelMask(_gl, mask, _channelMaskTexture);
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

			updateRegionMask (mask) {
	      this._gl.activeTexture(this._gl.TEXTURE1);
	      this._gl.bindTexture(this._gl.TEXTURE_2D, this._regionMaskTexture);
	      this._gl.pixelStorei(this._gl.UNPACK_FLIP_Y_WEBGL, true);
	      this._gl.texImage2D(this._gl.TEXTURE_2D, 0, this._gl.RGBA, this._gl.RGBA, this._gl.UNSIGNED_BYTE, mask);
	      this._regionMaskTexture = this._gl.bindTexture(this._gl.TEXTURE_2D, null);
	    };
}
