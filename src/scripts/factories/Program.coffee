# Factory for creating shader program objects
angular.module('quimbi').factory 'Program', ($document, input, mouse, settings) ->

	setUpDistanceTexture = (gl, assets, helpers) -> unless assets.framebuffers.distances
		assets.framebuffers.distances = gl.createFramebuffer()
		gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
		texture = helpers.newTexture 'distanceTexture'
		gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB,
			input.dataWidth, input.dataHeight,
			0, gl.RGB, gl.UNSIGNED_BYTE, null
		gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0
		gl.bindTexture gl.TEXTURE_2D, null
		gl.bindFramebuffer gl.FRAMEBUFFER, null

	setUpColorMapTexture = (gl, assets, helpers) -> unless assets.framebuffers.colorMapTexture
		assets.framebuffers.colorMapTexture = gl.createFramebuffer()
		gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.colorMapTexture
		texture = helpers.newTexture 'colorMapTexture'
		gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB,
			input.dataWidth, input.dataHeight,
			0, gl.RGB, gl.UNSIGNED_BYTE, null
		gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0
		gl.bindTexture gl.TEXTURE_2D, null
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
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA,
				input.dataWidth, input.dataHeight,
				0, gl.RGBA, gl.UNSIGNED_BYTE, null
		regionMaskTexture

	setUpImageTexture = (gl, program, assets, helpers) ->
		imageTexture = null
		gl.uniform1i gl.getUniformLocation(program, 'u_image'), 0
		# check if texture already exists
		unless imageTexture = assets.textures.imageTexture
			imageTexture = helpers.newTexture 'imageTexture'
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA,
			input.width, input.height,
			0, gl.RGBA, gl.UNSIGNED_BYTE, null

		image = new Image()
		image.onload = ->
			updateImageTexture gl, image, imageTexture
		image.src = input.backgroundImage

		imageTexture

	updateChannelMask = (gl, mask, texture) ->
		gl.activeTexture gl.TEXTURE0
		gl.bindTexture gl.TEXTURE_2D, texture
		gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, no
		gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, input.getChannelTextureDimension(),
				input.getChannelTextureDimension(), 0, gl.RGBA, gl.UNSIGNED_BYTE, mask
		gl.bindTexture gl.TEXTURE_2D, null

	updateRegionMask = (gl, mask, texture) ->
		gl.activeTexture gl.TEXTURE1
		gl.bindTexture gl.TEXTURE_2D, texture
		gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, yes
		gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, mask
		gl.bindTexture gl.TEXTURE_2D, null

	updateImageTexture = (gl, img, texture) ->
		clippedImage = $document[0].createElement 'canvas'
		clippedImage.width = input.width
		clippedImage.height = input.height
		clippedImageCtx = clippedImage.getContext '2d'
		clippedImageCtx.drawImage img, 0, 0, input.width * (1 + input.overlayShiftX), input.height * (1 + input.overlayShiftY)

		gl.activeTexture gl.TEXTURE2
		gl.bindTexture gl.TEXTURE_2D, texture
		gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, yes
		# can't explicitly specify width and height if an image is passed in
		gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, clippedImage
		gl.bindTexture gl.TEXTURE_2D, null

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
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.dataWidth, input.dataHeight
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
			gl.disable gl.BLEND

			gl.viewport 0, 0, input.dataWidth, input.dataHeight
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
		_regionMaskTexture = null
		# pointer to the uniform
		_channel = null

		@id = 'render-channel'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/render-channel.glsl.frag'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			helpers.useInternalTextures program

			_channel = gl.getUniformLocation program, 'u_channel'

			setUpDistanceTexture gl, assets, helpers

			_regionMaskTexture = setUpRegionMask gl, program, assets, helpers
			return

		@callback = (gl, program, assets, helpers) ->
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.dataWidth, input.dataHeight
			helpers.bindInternalTextures()
			gl.activeTexture gl.TEXTURE1
			gl.bindTexture gl.TEXTURE_2D, _regionMaskTexture
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
			return

		@updateRegionMask = (mask) ->
			updateRegionMask _gl, mask, _regionMaskTexture

		@updateChannel = (channel) ->
			_gl.uniform1f _channel, channel

		return

	# render the mean image of all channels in selected ranges
	RenderMeanRanges: ->
		_gl = null
		# pointers to texture objects
		_channelMaskTexture = null
		_regionMaskTexture = null
		# pointer to the uniform
		_invActiveChannels = null
		# number of active channels of the current channel mask
		_activeChannels = 0

		@id = 'render-mean-ranges'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/render-mean-ranges.glsl.frag'

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
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.dataWidth, input.dataHeight
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
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, input.dataWidth, input.dataHeight, 0, gl.RGB, gl.UNSIGNED_BYTE, null
			gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0
			gl.bindFramebuffer gl.FRAMEBUFFER, null

			rgb = gl.getUniformLocation program, 'u_rgb'
			gl.uniform1i rgb, 1

			_colorMaskLocation = gl.getUniformLocation program, 'u_color_mask'
			return

		@callback = (gl, program, assets, helpers) =>
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.dataWidth, input.dataHeight

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
	ColorMap: ->
		_colorMapTextureR = null
		_colorMapTextureG = null
		_colorMapTextureB = null
		_colorMask = [0, 0, 0]
		_colorMaskLocation = null
		_gl = null

		@id = 'color-map'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/color-map.glsl.frag'

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

			setUpColorMapTexture gl, assets, helpers

			_colorMaskLocation = gl.getUniformLocation program, 'u_color_mask'
			return

		@callback = (gl, program, assets, helpers) =>
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.dataWidth, input.dataHeight

			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, assets.textures.rgbTexture
			gl.activeTexture gl.TEXTURE1
			gl.bindTexture gl.TEXTURE_2D, _colorMapTextureR
			gl.activeTexture gl.TEXTURE2
			gl.bindTexture gl.TEXTURE_2D, _colorMapTextureG
			gl.activeTexture gl.TEXTURE3
			gl.bindTexture gl.TEXTURE_2D, _colorMapTextureB

			gl.uniform3f _colorMaskLocation, _colorMask[0], _colorMask[1], _colorMask[2]
			# use distance texture because it has the same dimensions and is not needed at the step
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.colorMapTexture
			return

		@updateColorMask = (mask) ->
			_colorMask[0] = mask[0]
			_colorMask[1] = mask[1]
			_colorMask[2] = mask[2]

		@updateColorMaps = (maps) ->
			_gl.activeTexture _gl.TEXTURE0
			_gl.bindTexture _gl.TEXTURE_2D, _colorMapTextureR
			if maps[0] then _gl.texImage2D _gl.TEXTURE_2D,
				0, _gl.RGB, 256, 1, 0, _gl.RGB, _gl.UNSIGNED_BYTE, maps[0]
			_gl.bindTexture _gl.TEXTURE_2D, _colorMapTextureG
			if maps[1] then _gl.texImage2D _gl.TEXTURE_2D,
				0, _gl.RGB, 256, 1, 0, _gl.RGB, _gl.UNSIGNED_BYTE, maps[1]
			_gl.bindTexture _gl.TEXTURE_2D, _colorMapTextureB
			if maps[2] then _gl.texImage2D _gl.TEXTURE_2D,
				0, _gl.RGB, 256, 1, 0, _gl.RGB, _gl.UNSIGNED_BYTE, maps[2]

		@updateColorMask = (mask) ->
			_colorMask[0] = mask[0]
			_colorMask[1] = mask[1]
			_colorMask[2] = mask[2]

		return

	DrawImage: ->
		_gl = null
		_imageTexture = null

		@id = 'draw-image'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/draw-image.glsl.frag'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			_imageTexture = setUpImageTexture gl, program, assets, helpers

			return

		@callback = (gl, program, assets, helpers) =>
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.width, input.height

			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, _imageTexture

			# render to screen
			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return

		return

	# applies a color map to the R channel of the rgb texture
	SpaceFillDisplay: ->
		_gl = null
		_spaceFillPercent = null

		@id = 'space-fill-display'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/space-fill-display.glsl.frag'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program

			rgb = gl.getUniformLocation program, 'u_color_map'
			gl.uniform1i rgb, 0

			# 0.0 .. 1.0, meaningfull are only steps in pixel size
			spaceFillPercent = 1.0
			renderScale = input.width / input.dataWidth
			halfPointSize = gl.getUniformLocation program, 'u_half_point_size'
			gl.uniform1f halfPointSize, (1.0 - spaceFillPercent) / 2.0

			# u_pixel_size; // i.e. vec2(1.0, 1.0) / texture_size;
			pixelSize = gl.getUniformLocation program, 'u_pixel_size'
			gl.uniform2f pixelSize, 1.0 / input.dataWidth, 1.0 / input.dataHeight

			return

		@callback = (gl, program, assets, helpers) =>
			# TODO find out where to disable blending in the other shaders to avoid
			#      side effects (currently disabled in every callback, which is probably overkill)
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.width, input.height

			if settings.useBlending
				# deactivate depth testing
				# TODO move this to initialization?
				# TODO do I need to disable depth testing at all?
				gl.disable gl.DEPTH_TEST

				# alternative blending, same effect as opaque canvas + background image
				# # transparent areas of SM are transparent, image is opaque
				# gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA
				# gl.blendEquation gl.FUNC_ADD

				gl.blendFunc gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA
				gl.blendEquation gl.FUNC_ADD
				gl.enable gl.BLEND

			gl.activeTexture gl.TEXTURE0
			# DEV try to use distance texture because it has the same dimensions and is not needed at the step (simply replacing doesn't work)
			gl.bindTexture gl.TEXTURE_2D, assets.textures.colorMapTexture

			# 0.0 .. 1.0, meaningfull are only steps in pixel size
			spaceFillPercent = settings.spaceFillPercent
			renderScale = input.width / input.dataWidth
			halfPointSize = gl.getUniformLocation program, 'u_half_point_size'
			gl.uniform1f halfPointSize, (1.0 - spaceFillPercent) / 2.0
			# render to screen
			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return

		@updateColorMask = (mask) ->
			_colorMask[0] = mask[0]
			_colorMask[1] = mask[1]
			_colorMask[2] = mask[2]

		return

	DrawImage: ->
		_gl = null
		_imageTexture = null

		@id = 'draw-image'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/draw-image.glsl.frag'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			_imageTexture = setUpImageTexture gl, program, assets, helpers

			return

		@callback = (gl, program, assets, helpers) =>
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.width, input.height

			gl.activeTexture gl.TEXTURE0
			gl.bindTexture gl.TEXTURE_2D, _imageTexture

			# render to screen
			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return

		return

	# applies a color map to the R channel of the rgb texture
	SpaceFillDisplay: ->
		_gl = null
		_spaceFillPercent = null

		@id = 'space-fill-display'

		@vertexShaderUrl = 'shader/display-rectangle.glsl.vert'

		@fragmentShaderUrl = 'shader/space-fill-display.glsl.frag'

		@constructor = (gl, program, assets, helpers) ->
			_gl = gl
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program

			rgb = gl.getUniformLocation program, 'u_color_map'
			gl.uniform1i rgb, 0

			# 0.0 .. 1.0, meaningfull are only steps in pixel size
			spaceFillPercent = 1.0
			renderScale = input.width / input.dataWidth
			halfPointSize = gl.getUniformLocation program, 'u_half_point_size'
			gl.uniform1f halfPointSize, (1.0 - spaceFillPercent) / 2.0

			# u_pixel_size; // i.e. vec2(1.0, 1.0) / texture_size;
			pixelSize = gl.getUniformLocation program, 'u_pixel_size'
			gl.uniform2f pixelSize, 1.0 / input.dataWidth, 1.0 / input.dataHeight

			return

		@callback = (gl, program, assets, helpers) =>
			# TODO find out where to disable blending in the other shaders to avoid
			#      side effects (currently disabled in every callback, which is probably overkill)
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.width, input.height

			if settings.useBlending
				# deactivate depth testing
				# TODO move this to initialization?
				# TODO do I need to disable depth testing at all?
				gl.disable gl.DEPTH_TEST

				# alternative blending, same effect as opaque canvas + background image
				# # transparent areas of SM are transparent, image is opaque
				# gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA
				# gl.blendEquation gl.FUNC_ADD

				gl.blendFunc gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA
				gl.blendEquation gl.FUNC_ADD
				gl.enable gl.BLEND

			gl.activeTexture gl.TEXTURE0
			# DEV try to use distance texture because it has the same dimensions and is not needed at the step (simply replacing doesn't work)
			gl.bindTexture gl.TEXTURE_2D, assets.textures.colorMapTexture

			# 0.0 .. 1.0, meaningfull are only steps in pixel size
			spaceFillPercent = settings.spaceFillPercent
			renderScale = input.width / input.dataWidth
			halfPointSize = gl.getUniformLocation program, 'u_half_point_size'
			gl.uniform1f halfPointSize, (1.0 - spaceFillPercent) / 2.0
			# render to screen
			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return

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
			gl.disable gl.BLEND
			gl.viewport 0, 0, input.getChannelTextureDimension(), input.getChannelTextureDimension()
			gl.uniform2f mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.selection
			return
		return
