# Factory for creating shader program objects
angular.module('quimbi').factory 'Program', (input, mouse, settings) ->

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
		gl.uniform1f gl.getUniformLocation(program, 'u_channel_mask_dimension'), input.getChannelTextureDimension()
		gl.uniform1f gl.getUniformLocation(program, 'u_inv_channel_mask_dimension'), 1 / input.getChannelTextureDimension()
		# check if texture already exists
		unless channelMaskTexture = assets.textures.channelMaskTexture
			channelMaskTexture = helpers.newTexture 'channelMaskTexture'
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, input.getChannelTextureDimension(),
				input.getChannelTextureDimension(), 0, gl.RGBA, gl.UNSIGNED_BYTE, null
		channelMaskTexture

	setUpRegionMask = (gl, program, assets, helpers) ->
		regionMaskTexture = null
		gl.uniform1i gl.getUniformLocation(program, 'u_region_mask'), 1
		# check if texture already exists
		unless regionMaskTexture = assets.textures.regionMaskTexture
			regionMaskTexture = helpers.newTexture 'regionMaskTexture'
			# same dimensions as distance texture
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, input.width,
				input.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null
		regionMaskTexture

	updateChannelMask = (gl, mask, texture) ->
		gl.activeTexture gl.TEXTURE0
		gl.bindTexture gl.TEXTURE_2D, texture
		gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, no
		gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, input.getChannelTextureDimension(),
				input.getChannelTextureDimension(), 0, gl.RGBA, gl.UNSIGNED_BYTE, mask

	updateRegionMask = (gl, mask, texture) ->
		gl.activeTexture gl.TEXTURE1
		gl.bindTexture gl.TEXTURE_2D, texture
		gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, yes
		gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, mask

	# euclidean distance
	EuclDist: ->
		_gl = null
		_mousePosition = null
		# pointers to texture objects
		_channelMaskTexture = null
		_regionMaskTexture = null

		@id = 'eucl-dist'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/eucl-dist.glsl.frag'

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
			_regionMaskTexture = setUpRegionMask gl, program, assets, helpers
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform2f _mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, _channelMaskTexture
			gl.activeTexture gl.TEXTURE1
			gl.bindTexture gl.TEXTURE_2D, _regionMaskTexture
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
			return

		@updateChannelMask = (mask) ->
			updateChannelMask _gl, mask, _channelMaskTexture

		@updateRegionMask = (mask) ->
			updateRegionMask _gl, mask, _regionMaskTexture
		return

	# angle distance
	AngleDist: ->
		_gl = null
		_mousePosition = null
		# pointers to texture objects
		_channelMaskTexture = null
		_regionMaskTexture = null

		@id = 'angle-dist'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/angle-dist.glsl.frag'

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
			_regionMaskTexture = setUpRegionMask gl, program, assets, helpers
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform2f _mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, _channelMaskTexture
			gl.activeTexture gl.TEXTURE1
			gl.bindTexture gl.TEXTURE_2D, _regionMaskTexture
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
			return

		@updateChannelMask = (mask) ->
			updateChannelMask _gl, mask, _channelMaskTexture

		@updateRegionMask = (mask) ->
			updateRegionMask _gl, mask, _regionMaskTexture

		return

	# render a single channel
	RenderChannel: ->
		_gl = null
		# pointers to texture objects
		_channelMaskTexture = null
		_regionMaskTexture = null
		# pointer to the uniform
		_invActiveChannels = null
		# number of active channels of the current channel mask
		_activeChannels = 0

		@id = 'render-channel'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/render-channel.glsl.frag'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			helpers.useInternalTextures program

			_invActiveChannels = gl.getUniformLocation program, 'u_inv_active_channels'

			setUpDistanceTexture gl, assets, helpers

			_channelMaskTexture = setUpChannelMask gl, program, assets, helpers
			_regionMaskTexture = setUpRegionMask gl, program, assets, helpers
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform1f _invActiveChannels, 1 / (_activeChannels || -1)
			helpers.bindInternalTextures()
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, _channelMaskTexture
			gl.activeTexture gl.TEXTURE1
			gl.bindTexture gl.TEXTURE_2D, _regionMaskTexture
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
			return

		@updateChannelMask = (mask, activeChannels) ->
			_activeChannels = activeChannels
			updateChannelMask _gl, mask, _channelMaskTexture

		@updateRegionMask = (mask) ->
			updateRegionMask _gl, mask, _regionMaskTexture

		return


	# handles multiple selections with own framebuffer texture
	RGBSelection: ->
		_colorMask = [0, 0, 0]
		_colorMaskLocation = null

		@id = 'rgb-selection'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/rgb-selection.glsl.frag'

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

			_colorMaskLocation = gl.getUniformLocation program, 'u_color_mask'
			return

		@callback = (gl, program, assets, helpers) =>
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, assets.textures.distanceTexture
			gl.activeTexture gl.TEXTURE1
			gl.bindTexture gl.TEXTURE_2D, assets.textures.rgbTexture

			gl.uniform3f _colorMaskLocation, _colorMask[0], _colorMask[1], _colorMask[2]

			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.rgb
			return

		@updateColorMask = (mask) ->
			_colorMask[0] = mask[0]
			_colorMask[1] = mask[1]
			_colorMask[2] = mask[2]

		return

	# applies a color map to the R channel of the rgb texture
	ColorMapDisplay: ->
		_colorMapTextureR = null
		_colorMapTextureG = null
		_colorMapTextureB = null
		_colorMask = [0, 0, 0]
		_colorMaskLocation = null
		_gl = null

		@id = 'color-map-display'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/grid-projection.glsl.frag' #'shader/color-map-display.glsl.frag'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program

			rgb = gl.getUniformLocation program, 'u_rgb'
			gl.uniform1i rgb, 0

			_colorMapTextureR = helpers.newTexture 'colorMapTextureR'
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, 256, 1, 0, gl.RGB, gl.UNSIGNED_BYTE, null
			_colorMapTextureG = helpers.newTexture 'colorMapTextureG'
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, 256, 1, 0, gl.RGB, gl.UNSIGNED_BYTE, null
			_colorMapTextureB = helpers.newTexture 'colorMapTextureB'
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, 256, 1, 0, gl.RGB, gl.UNSIGNED_BYTE, null

			gl.uniform1i gl.getUniformLocation(program, 'u_color_map_r'), 1
			gl.uniform1i gl.getUniformLocation(program, 'u_color_map_g'), 2
			gl.uniform1i gl.getUniformLocation(program, 'u_color_map_b'), 3

			_colorMaskLocation = gl.getUniformLocation program, 'u_color_mask'
			return

		@callback = (gl, program, assets, helpers) =>
			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, assets.textures.rgbTexture
			gl.activeTexture gl.TEXTURE1
			gl.bindTexture gl.TEXTURE_2D, _colorMapTextureR
			gl.activeTexture gl.TEXTURE2
			gl.bindTexture gl.TEXTURE_2D, _colorMapTextureG
			gl.activeTexture gl.TEXTURE3
			gl.bindTexture gl.TEXTURE_2D, _colorMapTextureB

			gl.uniform3f _colorMaskLocation, _colorMask[0], _colorMask[1], _colorMask[2]

			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return

		@updateColorMask = (mask) ->
			_colorMask[0] = mask[0]
			_colorMask[1] = mask[1]
			_colorMask[2] = mask[2]

		@updateColorMaps = (maps) ->
			_gl.activeTexture _gl.TEXTURE0
			_gl.bindTexture _gl.TEXTURE_2D, _colorMapTextureR
			_gl.texImage2D _gl.TEXTURE_2D, 0, _gl.RGB, 256, 1, 0, _gl.RGB, _gl.UNSIGNED_BYTE, maps[0]
			_gl.bindTexture _gl.TEXTURE_2D, _colorMapTextureG
			_gl.texImage2D _gl.TEXTURE_2D, 0, _gl.RGB, 256, 1, 0, _gl.RGB, _gl.UNSIGNED_BYTE, maps[1]
			_gl.bindTexture _gl.TEXTURE_2D, _colorMapTextureB
			_gl.texImage2D _gl.TEXTURE_2D, 0, _gl.RGB, 256, 1, 0, _gl.RGB, _gl.UNSIGNED_BYTE, maps[2]

		return

	# retrieves information about the selected position
	SelectionInfo: ->
		mousePosition = null;

		@id = 'selection-info'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/selection-info.glsl.frag'

		@constructor = (gl, program, assets, helpers) ->
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			helpers.useInternalTextures program

			mousePosition = gl.getUniformLocation program, 'u_mouse_position'

			dim = gl.getUniformLocation program, 'u_texture_dimension'
			gl.uniform1f dim, input.getChannelTextureDimension()

			assets.framebuffers.selection = gl.createFramebuffer()
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.selection
			texture = helpers.newTexture 'selectionTexture'
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, input.getChannelTextureDimension(), input.getChannelTextureDimension(), 0, gl.RGBA, gl.UNSIGNED_BYTE, null
			gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0
			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform2f mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.selection
			return
		return
