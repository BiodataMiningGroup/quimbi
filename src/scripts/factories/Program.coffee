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
			return

		@callback = (gl, program, assets, helpers) ->
			gl.uniform2f mousePosition, mouse.position.x, 1 - mouse.position.y
			helpers.bindInternalTextures()
			gl.bindFramebuffer gl.FRAMEBUFFER, null
			return
		return