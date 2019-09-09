import * as sharedFcts from './helper/sharedRenderFunctions.js';

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

			this.channelTextureDimension = this.framebuffer.selectionInfoTextureDimension;
			this.width = this.framebuffer.width;
			this.height = this.framebuffer.height;
		}

		setUp(gl, program, assets, helpers) {

				this._gl = gl;

				helpers.useInternalVertexPositions(program);
				helpers.useInternalTexturePositions(program);
				helpers.useInternalTextures(program);

			  this._invActiveChannels = gl.getUniformLocation(program, 'u_inv_active_channels');

				this.setUpDistanceTexture(gl, assets, helpers);

				this._channelMaskTexture = this.setUpChannelMask(gl, program, assets, helpers);
				this._regionMaskTexture = this.setUpRegionMask(gl, program, assets, helpers);
			};

			callback(gl, program, assets, helpers) {
				gl.uniform1f(this._invActiveChannels, 1 / (this._activeChannels || -1));
				helpers.bindInternalTextures();
				gl.activeTexture(gl.TEXTURE0);
				gl.bindTexture(gl.TEXTURE_2D, this._channelMaskTexture);
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
	    setUpChannelMask(gl, program, assets, helpers){
	      return sharedFcts.setUpChannelMask (gl, program, assets, helpers, this.channelTextureDimension);
	    }

			updateChannelMask(mask, activeChannels) {
				this._activeChannels = activeChannels;
				sharedFcts.updateChannelMask(this._gl, mask, this._channelMaskTexture);
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
}
