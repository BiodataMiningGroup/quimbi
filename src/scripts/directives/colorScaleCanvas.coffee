# directive to display the color scale's canvas
angular.module('quimbi').directive 'colorScaleCanvas', (markers, ranges, settings, colorMap, intensityHistogram, C) ->

	restrict: 'A'

	link: (scope, element) ->
		gl = element[0].getContext 'webgl'

		vertexShader = scope.compileShader gl,
			gl.createShader(gl.VERTEX_SHADER),
			scope.fetchShader 'shader/color-scale.glsl.vert'

		fragmentShader = scope.compileShader gl,
			gl.createShader(gl.FRAGMENT_SHADER),
			scope.fetchShader 'shader/color-scale.glsl.frag'

		program = scope.createProgram gl, vertexShader, fragmentShader

		gl.useProgram program

		# set up vertex coordinate buffer
		vertexCoordinateBuffer = gl.createBuffer()
		vertexCoordinates = gl.getAttribLocation program, 'a_vertex_position'
		gl.enableVertexAttribArray vertexCoordinates
		gl.bindBuffer gl.ARRAY_BUFFER, vertexCoordinateBuffer
		gl.vertexAttribPointer vertexCoordinates, 2, gl.FLOAT, false, 0, 0

		# set up vertex color buffer
		vertexColorBuffer = gl.createBuffer()
		vertexColor = gl.getAttribLocation program, 'a_vertex_color'
		gl.enableVertexAttribArray vertexColor
		gl.bindBuffer gl.ARRAY_BUFFER, vertexColorBuffer
		gl.vertexAttribPointer vertexColor, 3, gl.FLOAT, false, 0, 0

		# assign textures to texture units
		gl.uniform1i gl.getUniformLocation(program, 'u_color_map_r'), 0
		gl.uniform1i gl.getUniformLocation(program, 'u_color_map_g'), 1
		gl.uniform1i gl.getUniformLocation(program, 'u_color_map_b'), 2

		# the color map textures; one for each color channel
		colorMapTextures = [
			scope.newTexture gl
			scope.newTexture gl
			scope.newTexture gl
		]

		channelBoundsLocation = [
			gl.getUniformLocation program, 'u_channel_bounds_r'
			gl.getUniformLocation program, 'u_channel_bounds_g'
			gl.getUniformLocation program, 'u_channel_bounds_b'
		]

		channelBounds = null

		# returns the list of markers/ranges groups
		# not just their length because the color scale should re-render when
		# a group changes, too
		getCurrentList = -> switch settings.displayMode
			when C.DISPLAY_MODE.MEAN then ranges.currentGroups()
			else markers.getList()

		updateChannelBounds = ->
			channelBounds = intensityHistogram.getChannelBounds()
			gl.uniform2f channelBoundsLocation[0], channelBounds[0].min,
				1 / ((channelBounds[0].max || 1) - channelBounds[0].min)
			gl.uniform2f channelBoundsLocation[1], channelBounds[1].min,
				1 / ((channelBounds[1].max || 1) - channelBounds[1].min)
			gl.uniform2f channelBoundsLocation[2], channelBounds[2].min,
				1 / ((channelBounds[2].max || 1) - channelBounds[2].min)

		# updates the color scale (depends on the current dimension)
		updateScale = ->
			list = getCurrentList()
			updateChannelBounds()
			switch list.length
				when 1 then scope.render1D gl,
					vertexCoordinateBuffer, vertexColorBuffer, list
				when 2 then scope.render2D gl,
					vertexCoordinateBuffer, vertexColorBuffer, list

		# fill textures with currently active color maps
		updateColorMaps = (colorMaps) ->
			for map, index in colorMaps when map
				gl.activeTexture gl.TEXTURE0 + index
				gl.bindTexture gl.TEXTURE_2D, colorMapTextures[index]
				gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, 256, 1, 0, gl.RGB,
					gl.UNSIGNED_BYTE, colorMap.get map
			updateScale getCurrentList()

		# this has to be put BEFORE updateColorMapCountWatcher! so the textures are
		# initially updated before rendering
		scope.$watch (-> settings.activeColorMaps), updateColorMaps, yes

		scope.$on 'renderer.updated', updateScale

		return

	controller: ($scope) ->

		# get the shader file
		$scope.fetchShader = (url) ->
			xhr = new XMLHttpRequest()
			xhr.overrideMimeType 'text/plain'
			xhr.open 'get', url, no
			xhr.send()
			xhr.responseText

		# compile the shader file string to a webgl shader
		$scope.compileShader = (gl, shader, source) ->
			gl.shaderSource shader, source
			gl.compileShader shader
			unless gl.getShaderParameter shader, gl.COMPILE_STATUS
				console.error "#{gl.getShaderInfoLog shader}"
			shader

		# build webgl program out of shaders
		$scope.createProgram = (gl, vertexShader, fragmentShader) ->
			program = gl.createProgram()
			gl.attachShader program, vertexShader
			gl.attachShader program, fragmentShader
			gl.linkProgram program
			unless gl.getProgramParameter program, gl.LINK_STATUS
				console.error "#{gl.getProgramInfoLog program}"
			program

		# create a new texture
		$scope.newTexture = (gl) ->
			texture = gl.createTexture()
			gl.bindTexture gl.TEXTURE_2D, texture
			gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
			gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
			gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
			gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
			texture

		# render the color scale for the 1D case
		$scope.render1D = (gl, coordinateBuffer, colorBuffer, list) ->
			gl.bindBuffer gl.ARRAY_BUFFER, coordinateBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexCoordinatesQuad, gl.STATIC_DRAW
			gl.bindBuffer gl.ARRAY_BUFFER, colorBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexColors1D(list), gl.STATIC_DRAW
			gl.drawArrays gl.TRIANGLES, 0, 6

		# render the color scale for the 2D case
		$scope.render2D = (gl, coordinateBuffer, colorBuffer, list) ->
			gl.bindBuffer gl.ARRAY_BUFFER, coordinateBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexCoordinatesQuad, gl.STATIC_DRAW
			gl.bindBuffer gl.ARRAY_BUFFER, colorBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexColors2D(list), gl.STATIC_DRAW
			gl.drawArrays gl.TRIANGLES, 0, 6

		clearArray = (array) ->	array[i] = 0 for i in [0...array.length]

		# vertex coordinates for a quad (1D and 2D)
		$scope.vertexCoordinatesQuad = new Float32Array [
			-1, -1
			-1,  1
			 1, -1
			-1,  1
			 1, -1
			 1,  1
		]

		# colors assigned to the quad vertices
		vertexColorsQuad = new Float32Array [
			0, 0, 0
			0, 0, 0
			0, 0, 0
			0, 0, 0
			0, 0, 0
			0, 0, 0
		]

		# assign the vertex colors according to the active markers/ranges in 1D
		$scope.vertexColors1D = (list) ->
			if settings.displayMode is C.DISPLAY_MODE.MEAN
				index = list[0]
			else
				index = list[0].getIndex()
			clearArray vertexColorsQuad
			for i in [1..5] by 2
				vertexColorsQuad[3 * i + index] = 1
			vertexColorsQuad

		# assign the vertex colors according to the active markers/ranges in 2D
		$scope.vertexColors2D = (list) ->
			if settings.displayMode is C.DISPLAY_MODE.MEAN
				index0 = list[0]
				index1 = list[1]
			else
				index0 = list[0].getIndex()
				index1 = list[1].getIndex()

			clearArray vertexColorsQuad

			vertexColorsQuad[index0] = 1
			for i in [1..3] by 2
				vertexColorsQuad[3 * i + index0] = vertexColorsQuad[3 * i + index1] = 1
			vertexColorsQuad[vertexColorsQuad.length - 3 + index1] = 1

			vertexColorsQuad

		return
