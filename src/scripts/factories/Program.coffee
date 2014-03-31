# Factory for creating shader program objects
angular.module('quimbi').factory 'Program', (input, mouse, selection, settings) ->

	setUpDistanceTexture = (gl, assets, helpers) -> unless assets.framebuffers.distances
		assets.framebuffers.distances = gl.createFramebuffer()
		gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
		texture = helpers.newTexture 'distanceTexture'
		gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, input.width, input.height, 0, gl.RGB, gl.UNSIGNED_BYTE, null
		gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0
		gl.bindFramebuffer gl.FRAMEBUFFER, null

	setUpChannelMask = (gl, program, assets, helpers) ->
		channelMaskTexture = null
		gl.uniform1i gl.getUniformLocation(program, 'u_channel_mask'), 0
		gl.uniform1f gl.getUniformLocation(program, 'u_channel_mask_dimension'), selection.textureDimension
		gl.uniform1f gl.getUniformLocation(program, 'u_inv_channel_mask_dimension'), 1/selection.textureDimension
		# check if texture already exists
		unless channelMaskTexture = assets.textures.channelMaskTexture
			channelMaskTexture = helpers.newTexture 'channelMaskTexture'
			# same dimensions as fingerprint texture from selection
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, selection.textureDimension,
				selection.textureDimension, 0, gl.RGBA, gl.UNSIGNED_BYTE, null
		channelMaskTexture

	updateChannelMask = (gl, mask, texture) ->
		gl.activeTexture gl.TEXTURE0
		gl.bindTexture gl.TEXTURE_2D, texture
		gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, no
		gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, selection.textureDimension,
				selection.textureDimension, 0, gl.RGBA, gl.UNSIGNED_BYTE, mask


	# euclidean distance
	EuclDist: ->
		_gl = null
		_mousePosition = null
		# pointer to texture object
		_channelMaskTexture = null

		@id = 'eucl-dist'

		@vertexShaderUrl = 'shader/display-rectangle.vs.glsl'

		@fragmentShaderUrl = 'shader/eucl-dist.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			helpers.useInternalTextures program

			normalization = gl.getUniformLocation program, 'u_normalization'
			gl.uniform1f normalization, 255 / input.maxEuclDist

			_mousePosition = gl.getUniformLocation program, 'u_mouse_position'

			setUpDistanceTexture gl, assets, helpers

			_channelMaskTexture = setUpChannelMask gl, program, assets, helpers
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform2f _mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, _channelMaskTexture
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
			return

		@updateChannelMask = (mask) ->
			updateChannelMask _gl, mask, _channelMaskTexture
		return

	# angle distance
	AngleDist: ->
		_gl = null
		_mousePosition = null
		# pointer to texture object
		_channelMaskTexture = null

		@id = 'angle-dist'

		@vertexShaderUrl = 'shader/display-rectangle.vs.glsl'

		@fragmentShaderUrl = 'shader/angle-dist.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			helpers.useInternalTextures program

			normalization = gl.getUniformLocation program, 'u_normalization'
			gl.uniform1f normalization, 1 / input.maxAngleDist

			_mousePosition = gl.getUniformLocation program, 'u_mouse_position'

			setUpDistanceTexture gl, assets, helpers

			_channelMaskTexture = setUpChannelMask gl, program, assets, helpers
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform2f _mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, _channelMaskTexture
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
			return

		@updateChannelMask = (mask) ->
			updateChannelMask _gl, mask, _channelMaskTexture

		return

	# render a single channel
	RenderChannel: ->
		_gl = null
		# pointer to texture object
		_channelMaskTexture = null
		# pointer to the uniform
		_invActiveChannels = null
		# number of active channels of the current channel mask
		_activeChannels = 0

		@id = 'render-channel'

		@vertexShaderUrl = 'shader/display-rectangle.vs.glsl'

		@fragmentShaderUrl = 'shader/render-channel.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			helpers.useInternalTextures program

			_invActiveChannels = gl.getUniformLocation program, 'u_inv_active_channels'

			setUpDistanceTexture gl, assets, helpers

			_channelMaskTexture = setUpChannelMask gl, program, assets, helpers

			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform1f _invActiveChannels, 1 / (_activeChannels || -1)
			helpers.bindInternalTextures()
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, _channelMaskTexture
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
			return

		@updateChannelMask = (mask, activeChannels) ->
			_activeChannels = activeChannels
			updateChannelMask _gl, mask, _channelMaskTexture

		return


	# handles multiple selections with own framebuffer texture
	RGBSelection: ->
		colorMask = null

		@colorMask = [0, 0, 0]

		@id = 'rgb-selection'

		@vertexShaderUrl = 'shader/display-rectangle.vs.glsl'

		@fragmentShaderUrl = 'shader/rgb-selection.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program

			distances = gl.getUniformLocation program, 'u_distances'
			gl.uniform1i distances, 0

			assets.framebuffers.rgb = gl.createFramebuffer()
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.rgb
			texture = helpers.newTexture 'rgbTexture'
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, input.width, input.height, 0, gl.RGB, gl.UNSIGNED_BYTE, null
			gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0
			gl.bindFramebuffer gl.FRAMEBUFFER, null

			rgb = gl.getUniformLocation program, 'u_rgb'
			gl.uniform1i rgb, 1

			colorMask = gl.getUniformLocation program, 'u_color_mask'
			return

		@callback = (gl, program, assets, helpers) =>
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, assets.textures.distanceTexture
			gl.activeTexture gl.TEXTURE1
			gl.bindTexture gl.TEXTURE_2D, assets.textures.rgbTexture

			gl.uniform3f colorMask, @colorMask[0], @colorMask[1], @colorMask[2]

			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.rgb
			return
		return

	# determines the final display from the rgb texture
	PseudocolorDisplay: ->
		colorMask = null

		@colorMask = [0, 0, 0]

		@id = 'pseudocolor-display'

		@vertexShaderUrl = 'shader/display-rectangle.vs.glsl'

		@fragmentShaderUrl = 'shader/pseudocolor-display.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			helpers.useInternalVertexPositions program

			helpers.useInternalTexturePositions program

			rgb = gl.getUniformLocation program, 'u_rgb'
			gl.uniform1i rgb, 0

			colorMask = gl.getUniformLocation program, 'u_color_mask'
			return

		@callback = (gl, program, assets, helpers) =>
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, assets.textures.rgbTexture

			gl.uniform3f colorMask, @colorMask[0], @colorMask[1], @colorMask[2]

			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return
		return

	# applies a color map to the R channel of the rgb texture
	ColorMapDisplay: ->
		@id = 'color-map-display'

		@vertexShaderUrl = 'shader/display-rectangle.vs.glsl'

		@fragmentShaderUrl = 'shader/color-map-display.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program

			rgb = gl.getUniformLocation program, 'u_rgb'
			gl.uniform1i rgb, 0

			texture = helpers.newTexture 'colorMapTexture'
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, 256, 1, 0, gl.RGB, gl.UNSIGNED_BYTE, null

			colorMap = gl.getUniformLocation program, 'u_color_map'
			gl.uniform1i colorMap, 1

			return

		@callback = (gl, program, assets, helpers) =>
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, assets.textures.rgbTexture
			gl.activeTexture gl.TEXTURE1
			gl.bindTexture gl.TEXTURE_2D, assets.textures.colorMapTexture
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, 256, 1, 0, gl.RGB, gl.UNSIGNED_BYTE, settings.colorMap

			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return
		return

	# retrieves information about the selected position
	SelectionInfo: ->
		mousePosition = null;

		@id = 'selection-info'

		@vertexShaderUrl = 'shader/display-rectangle.vs.glsl'

		@fragmentShaderUrl = 'shader/selection-info.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			helpers.useInternalTextures program

			mousePosition = gl.getUniformLocation program, 'u_mouse_position'

			dim = gl.getUniformLocation program, 'u_texture_dimension'
			gl.uniform1f dim, selection.textureDimension

			assets.framebuffers.selection = gl.createFramebuffer()
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.selection
			texture = helpers.newTexture 'selectionTexture'
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, selection.textureDimension, selection.textureDimension, 0, gl.RGBA, gl.UNSIGNED_BYTE, null
			gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0
			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform2f mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.selection
			return
		return
