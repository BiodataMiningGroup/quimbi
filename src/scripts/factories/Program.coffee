# Factory for creating shader program objects
angular.module('quimbi').factory 'Program', (input, mouse, selection) ->
	# euclidean distance
	EuclDist: ->
		mousePosition = null;

		@id = 'eucl-dist'

		@vertexShaderUrl = 'shader/display-rectangle.vs.glsl'

		@fragmentShaderUrl = 'shader/eucl-dist.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			helpers.useInternalTextures program

			normalization = gl.getUniformLocation program, 'u_normalization'
			gl.uniform1f normalization, 255 / input.maxEuclDist

			mousePosition = gl.getUniformLocation program, 'u_mouse_position'

			unless assets.framebuffers.distances
				assets.framebuffers.distances = gl.createFramebuffer()
				gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
				texture = helpers.newTexture 'distanceTexture'
				gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, input.width, input.height, 0, gl.RGB, gl.UNSIGNED_BYTE, null
				gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0
				gl.bindFramebuffer gl.FRAMEBUFFER, null
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform2f mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
			return
		return

	# angle distance
	AngleDist: ->
		mousePosition = null;

		@id = 'angle-dist'

		@vertexShaderUrl = 'shader/display-rectangle.vs.glsl'

		@fragmentShaderUrl = 'shader/angle-dist.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			helpers.useInternalVertexPositions program
			helpers.useInternalTexturePositions program
			helpers.useInternalTextures program

			normalization = gl.getUniformLocation program, 'u_normalization'
			gl.uniform1f normalization, 1 / input.maxAngleDist

			mousePosition = gl.getUniformLocation program, 'u_mouse_position'

			unless assets.framebuffers.distances
				assets.framebuffers.distances = gl.createFramebuffer()
				gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
				texture = helpers.newTexture 'distanceTexture'
				gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, input.width, input.height, 0, gl.RGB, gl.UNSIGNED_BYTE, null
				gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0
				gl.bindFramebuffer gl.FRAMEBUFFER, null
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform2f mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.bindFramebuffer gl.FRAMEBUFFER, assets.framebuffers.distances
			return
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