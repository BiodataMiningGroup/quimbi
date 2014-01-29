# Factory for creating shader program objects
angular.module('quimbi').factory 'Program', (input, mouse) ->
	# euclidean distance
	EuclDist: ->
		mousePosition = null;

		@id = 'eucl-dist'

		@vertexShader = 'shader/display-rectangle.vs.glsl'

		@fragmentShader = 'shader/eucl-dist.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			vertexCoordinates = gl.getAttribLocation program, 'a_vertex_position'
			gl.enableVertexAttribArray vertexCoordinates
			gl.bindBuffer gl.ARRAY_BUFFER, assets.buffers.vertexCoordinateBuffer
			gl.vertexAttribPointer vertexCoordinates, 2, gl.FLOAT, false, 0, 0

			textureCoordinates = gl.getAttribLocation program, 'a_texture_position'
			gl.enableVertexAttribArray textureCoordinates
			gl.bindBuffer gl.ARRAY_BUFFER, assets.buffers.textureCoordinateBuffer
			gl.vertexAttribPointer textureCoordinates, 2, gl.FLOAT, false, 0, 0

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

		@vertexShader = 'shader/display-rectangle.vs.glsl'

		@fragmentShader = 'shader/angle-dist.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			vertexCoordinates = gl.getAttribLocation program, 'a_vertex_position'
			gl.enableVertexAttribArray vertexCoordinates
			gl.bindBuffer gl.ARRAY_BUFFER, assets.buffers.vertexCoordinateBuffer
			gl.vertexAttribPointer vertexCoordinates, 2, gl.FLOAT, false, 0, 0

			textureCoordinates = gl.getAttribLocation program, 'a_texture_position'
			gl.enableVertexAttribArray textureCoordinates
			gl.bindBuffer gl.ARRAY_BUFFER, assets.buffers.textureCoordinateBuffer
			gl.vertexAttribPointer textureCoordinates, 2, gl.FLOAT, false, 0, 0

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

		@vertexShader = 'shader/display-rectangle.vs.glsl'

		@fragmentShader = 'shader/rgb-selection.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			vertexCoordinates = gl.getAttribLocation program, 'a_vertex_position'
			gl.enableVertexAttribArray vertexCoordinates
			gl.bindBuffer gl.ARRAY_BUFFER, assets.buffers.vertexCoordinateBuffer
			gl.vertexAttribPointer vertexCoordinates, 2, gl.FLOAT, false, 0, 0

			textureCoordinates = gl.getAttribLocation program, 'a_texture_position'
			gl.enableVertexAttribArray textureCoordinates
			gl.bindBuffer gl.ARRAY_BUFFER, assets.buffers.textureCoordinateBuffer
			gl.vertexAttribPointer textureCoordinates, 2, gl.FLOAT, false, 0, 0

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

		@vertexShader = 'shader/display-rectangle.vs.glsl'

		@fragmentShader = 'shader/pseudocolor-display.fs.glsl'

		@constructor = (gl, program, assets, helpers) ->
			vertexCoordinates = gl.getAttribLocation program, 'a_vertex_position'
			gl.enableVertexAttribArray vertexCoordinates
			gl.bindBuffer gl.ARRAY_BUFFER, assets.buffers.vertexCoordinateBuffer
			gl.vertexAttribPointer vertexCoordinates, 2, gl.FLOAT, false, 0, 0

			textureCoordinates = gl.getAttribLocation program, 'a_texture_position'
			gl.enableVertexAttribArray textureCoordinates
			gl.bindBuffer gl.ARRAY_BUFFER, assets.buffers.textureCoordinateBuffer
			gl.vertexAttribPointer textureCoordinates, 2, gl.FLOAT, false, 0, 0

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