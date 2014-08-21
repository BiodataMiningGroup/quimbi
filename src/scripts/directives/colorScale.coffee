# directive to display a color scale of all present markers
angular.module('quimbi').directive 'colorScale', (markers, ranges, settings, colorScaleIndicator, intensityHistogram, C) ->
	
	restrict: 'A'

	templateUrl: 'templates/colorScale.html'

	replace: yes

	controller: ($scope) ->
		# full width/height of the color scale
		fullWidth = 256
		# smaller width of the color scale (for 1D)
		smallWidth = 30

		# channel intensities of the hovered pixel on the map
		intensities = [0, 0, 0, 0]

		# normalized, so r+g+b=1
		normalizedIntensities = [0, 0, 0, 0]

		# currently active color channels (0, 1 and/or 2)
		activeIndices = []

		# number of currently active color channels
		dimension = 0

		# array of bounds of the normalized color scale
		bounds = intensityHistogram.getChannelBounds()

		# the styles of the 4 color scale bounds elements
		$scope.boundsStyles =
			top: display: 'none'
			bottom: display: 'none'
			left: display: 'none'
			right: display: 'none'

		# the points/vertices of the 3D color scale triangle
		point3D =
			bottomLeft: x: 0, y: fullWidth
			bottomRight: x: fullWidth, y: fullWidth
			top: x: fullWidth / 2, y: 0

		# returns the active color channel indices
		getActiveIndices = -> switch settings.displayMode
			when C.DISPLAY_MODE.DIRECT then [0]
			when C.DISPLAY_MODE.MEAN then ranges.currentGroups()
			else marker.getIndex() for marker in markers.getList()

		# returns a transform: translate CSS style object for ng-style
		translateCSS = (x, y) ->
			x = Math.round x
			y = Math.round y
			'transform': "translate(#{x}px,#{y}px)"
			'webkit-transform': "translate(#{x}px,#{y}px)"

		# hides the color scale when no marker exists
		$scope.colorScaleClass = ->
			output = ''
			output += "color-scale--#{dimension}d"
			output

		# determines the dimension of the color scale element
		$scope.colorScaleDimension = -> switch dimension
			when 1
				width: "#{smallWidth}px"
				height: "#{fullWidth}px"
			else
				width: "#{fullWidth}px"
				height: "#{fullWidth}px"

		$scope.showHistogram = -> dimension is 1

		$scope.showCanvas = -> 0 < dimension < 3

		$scope.showTriangle = -> dimension is 3

		# positions the indicator on the 1D color scale
		indicatorStyle1D = -> translateCSS smallWidth * 0.5,
			fullWidth * (1-intensities[activeIndices[0]])

		# positions the indicator on the 2D color scale
		indicatorStyle2D = -> translateCSS fullWidth * (1-intensities[activeIndices[0]]),
			fullWidth * (1-intensities[activeIndices[1]])

		# positions the indicator on the 3D color scale
		indicatorStyle3D = ->
			intensityR = normalizedIntensities[activeIndices[0]]
			intensityG = normalizedIntensities[activeIndices[1]]
			intensityB = normalizedIntensities[activeIndices[2]]
			x = intensityR * point3D.bottomLeft.x +
				intensityG * point3D.bottomRight.x +
				intensityB * point3D.top.x
			y = intensityR * point3D.bottomLeft.y +
				intensityG * point3D.bottomRight.y +
				intensityB * point3D.top.y
			translateCSS x, y

		# mixes a css rgb color to match the color of the currently hovered
		# pixel according to the active color maps
		indicatorColor = ->
			color = colorScaleIndicator.getColor()
			"rgb(#{color[0]}, #{color[1]}, #{color[2]})"

		# returns the style for the indicator
		$scope.indicatorStyle = ->
			output = switch dimension
				when 1 then indicatorStyle1D()
				when 2 then indicatorStyle2D()
				when 3 then indicatorStyle3D()
				else {}
			output['background-color'] = indicatorColor()
			# dont display indicator if mouse hovers over transparent pixel
			output['display'] = 'none' if intensities[3] is 0
			output

		# positions the top and bottom bounds elements in 1D
		boundsStyles1D = ->
			left: display: 'none'
			right: display: 'none'
			top: translateCSS 0, Math.round (1 - bounds[activeIndices[0]].max) * fullWidth
			bottom: translateCSS 0, Math.round (1 - bounds[activeIndices[0]].min) * fullWidth

		# positions all 4 bounds elements in 2D
		boundsStyles2D = ->
			boundingBox =
				left: Math.round (1 - bounds[activeIndices[0]].max) * fullWidth
				right: Math.round (1 - bounds[activeIndices[0]].min) * fullWidth
				top: Math.round (1 - bounds[activeIndices[1]].max) * fullWidth
				bottom: Math.round (1 - bounds[activeIndices[1]].min) * fullWidth

			output =
				left: translateCSS boundingBox.left, boundingBox.top
				right: translateCSS boundingBox.right, boundingBox.top
				top: translateCSS boundingBox.left, boundingBox.top
				bottom: translateCSS boundingBox.left, boundingBox.bottom
			output.left.height = output.right.height = "#{boundingBox.bottom - boundingBox.top}px"
			output.top.width = output.bottom.width = "#{boundingBox.right - boundingBox.left}px"

			output

		updateBoundsStyles = ->	$scope.boundsStyles = switch dimension
			when 1 then boundsStyles1D()
			when 2 then boundsStyles2D()

		# returns the single colors for the vertices of the 3D coolor scale triangle
		$scope.vertex3DColor = (index) ->
			color = settings.colorMapSingleColors[activeIndices[index]]
			'background-color': if color then color else ''

		$scope.$watchCollection colorScaleIndicator.getIntensities, (newIntensities) ->
			for intensity, index in newIntensities
				intensities[index] = intensity / 255
			normalizedIntensities = colorScaleIndicator.getNormalizedIntensities()

		$scope.$watchCollection getActiveIndices, (newActiveIndices) ->
			dimension = newActiveIndices.length
			activeIndices = newActiveIndices
			updateBoundsStyles()

		$scope.$on 'renderer.updated', ->
			bounds = intensityHistogram.getChannelBounds()
			updateBoundsStyles()
		
		return