# directive to read a local text file
angular.module('quimbi').directive 'colorScaleCanvas', (markers, ranges, settings, colorMap) ->
	
	restrict: 'A'

	link: (scope, element) ->
		gl = element[0].getContext 'webgl'

		vertexShader = scope.compileShader gl,
			gl.createShader(gl.VERTEX_SHADER),
			scope.fetchShader 'shader/color-scale.vs.glsl'

		fragmentShader = scope.compileShader gl,
			gl.createShader(gl.FRAGMENT_SHADER),
			scope.fetchShader 'shader/color-scale.fs.glsl'

		program = scope.createProgram gl, vertexShader, fragmentShader

		gl.useProgram program

		vertexCoordinateBuffer = gl.createBuffer()
		vertexCoordinates = gl.getAttribLocation program, 'a_vertex_position'
		gl.enableVertexAttribArray vertexCoordinates
		gl.bindBuffer gl.ARRAY_BUFFER, vertexCoordinateBuffer
		gl.vertexAttribPointer vertexCoordinates, 2, gl.FLOAT, false, 0, 0

		vertexColorBuffer = gl.createBuffer()
		vertexColor = gl.getAttribLocation program, 'a_vertex_color'
		gl.enableVertexAttribArray vertexColor
		gl.bindBuffer gl.ARRAY_BUFFER, vertexColorBuffer
		gl.vertexAttribPointer vertexColor, 3, gl.FLOAT, false, 0, 0

		gl.uniform1i gl.getUniformLocation(program, 'u_color_map_r'), 0
		gl.uniform1i gl.getUniformLocation(program, 'u_color_map_g'), 1
		gl.uniform1i gl.getUniformLocation(program, 'u_color_map_b'), 2

		for map, index in settings.colorMaps
			gl.activeTexture gl.TEXTURE0 + index
			texture = scope.newTexture gl
			gl.texImage2D gl.TEXTURE_2D, 0, gl.RGB, 256, 1, 0, gl.RGB,
				gl.UNSIGNED_BYTE, colorMap.get map

		updateScale = (list) -> switch list.length
			when 1 then scope.render1D gl, vertexCoordinateBuffer, vertexColorBuffer, list
			when 2 then scope.render2D gl, vertexCoordinateBuffer, vertexColorBuffer, list
			when 3 then scope.render3D gl, vertexCoordinateBuffer, vertexColorBuffer, list

		cancelWatch = angular.noop

		updateColorMapCountWatcher = (displayMode) ->
			cancelWatch()
			switch displayMode
				when 'mean'
					cancelWatch = scope.$watchCollection (-> ranges.currentGroups()), updateScale
				else
					cancelWatch = scope.$watchCollection (-> markers.getList()), updateScale

		scope.$watch (-> settings.displayMode), updateColorMapCountWatcher

		return

	controller: ($scope) ->

		$scope.fetchShader = (url) ->
			xhr = new XMLHttpRequest()
			xhr.overrideMimeType 'text/plain'
			xhr.open 'get', url, no
			xhr.send()
			xhr.responseText

		$scope.compileShader = (gl, shader, source) ->
			gl.shaderSource shader, source
			gl.compileShader shader
			unless gl.getShaderParameter shader, gl.COMPILE_STATUS
				console.error "#{gl.getShaderInfoLog shader}"
			shader

		$scope.createProgram = (gl, vertexShader, fragmentShader) ->
			program = gl.createProgram()
			gl.attachShader program, vertexShader
			gl.attachShader program, fragmentShader
			gl.linkProgram program
			unless gl.getProgramParameter program, gl.LINK_STATUS
				console.error "#{gl.getProgramInfoLog program}"
			program

		$scope.newTexture = (gl) ->
			texture = gl.createTexture()
			gl.bindTexture gl.TEXTURE_2D, texture
			gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
			gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
			gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
			gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
			texture

		$scope.render1D = (gl, coordinateBuffer, colorBuffer, list) ->
			gl.bindBuffer gl.ARRAY_BUFFER, coordinateBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexCoordinatesQuad, gl.STATIC_DRAW
			gl.bindBuffer gl.ARRAY_BUFFER, colorBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexColors1D(list), gl.STATIC_DRAW
			gl.drawArrays gl.TRIANGLES, 0, 6

		$scope.render2D = (gl, coordinateBuffer, colorBuffer, list) ->
			gl.bindBuffer gl.ARRAY_BUFFER, coordinateBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexCoordinatesQuad, gl.STATIC_DRAW
			gl.bindBuffer gl.ARRAY_BUFFER, colorBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexColors2D(list), gl.STATIC_DRAW
			gl.drawArrays gl.TRIANGLES, 0, 6

		$scope.render3D = (gl, coordinateBuffer, colorBuffer, list) ->
			gl.bindBuffer gl.ARRAY_BUFFER, coordinateBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexCoordinatesTriangle, gl.STATIC_DRAW
			gl.bindBuffer gl.ARRAY_BUFFER, colorBuffer
			gl.bufferData gl.ARRAY_BUFFER, $scope.vertexColors3D(list), gl.STATIC_DRAW
			gl.drawArrays gl.TRIANGLES, 0, 3

		clearArray = (array) ->	array[i] = 0 for i in [0...array.length]

		$scope.vertexCoordinatesQuad = new Float32Array [
			-1, -1
			-1,  1
			 1, -1
			-1,  1
			 1, -1
			 1,  1
		]

		vertexColorsQuad = new Float32Array [
			0, 0, 0
			0, 0, 0
			0, 0, 0
			0, 0, 0
			0, 0, 0
			0, 0, 0
		]

		$scope.vertexColors1D = (list) ->
			if settings.displayMode is 'mean'
				index = list[0]
			else
				index = list[0].getColorMaskIndex()
			clearArray vertexColorsQuad
			for i in [1..5] by 2
				vertexColorsQuad[3 * i + index] = 1
			vertexColorsQuad

		$scope.vertexColors2D = (list) ->
			if settings.displayMode is 'mean'
				index0 = list[0]
				index1 = list[1]
			else
				index0 = list[0].getColorMaskIndex()
				index1 = list[1].getColorMaskIndex()

			clearArray vertexColorsQuad

			vertexColorsQuad[index0] = 1
			for i in [1..3] by 2
				vertexColorsQuad[3 * i + index0] = vertexColorsQuad[3 * i + index1] = 1
			vertexColorsQuad[vertexColorsQuad.length - 3 + index1] = 1

			vertexColorsQuad

		$scope.vertexCoordinatesTriangle = new Float32Array [
			-1, -1
			 1, -1
			 0,  1
		]

		vertexColorsTriangle = new Float32Array [
			1, 0, 0
			0, 1, 0
			0, 0, 1
		]

		$scope.vertexColors3D = (list) ->
			clearArray vertexColorsTriangle

			if settings.displayMode is 'mean'
				for group, index in list
					vertexColorsTriangle[3 * index + group] = 1
			else
				for marker, index in list
					vertexColorsTriangle[3 * index + marker.getColorMaskIndex()] = 1
			vertexColorsTriangle

		return