# Shader program object to render a single tile
angular.module('quimbi').factory 'TileProgram', ->
	# constructor function
	->
		@id = 'tile'

		@vertexShader = 'shader/display-rectangle.vs'

		@fragmentShader = 'shader/tile.fs'

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

		@callback = (gl, program, assets, helpers) ->
			helpers.bindInternalTextures()
			gl.bindFramebuffer gl.FRAMEBUFFER, null
		return