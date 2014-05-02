# directive to read a local text file
angular.module('quimbi').directive 'colorScale', (markers, ranges, settings, colorScaleIndicator) ->
	
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

		# the points/vertices of the 3D color scale triangle
		point3D =
			bottomLeft: x: 0, y: fullWidth
			bottomRight: x: fullWidth, y: fullWidth
			top: x: fullWidth / 2, y: 0

		# returns the active color channel indices
		getActiveIndices = -> switch settings.displayMode
			when 'mean' then ranges.currentGroups()
			else marker.getColorMaskIndex() for marker in markers.getList()

		# returns a transform: translate CSS style object for ng-style
		translateCSS = (x, y) ->
			x = Math.round x
			y = Math.round y
			'transform': "translate(#{x}px,#{y}px)"
			'webkit-transform': "translate(#{x}px,#{y}px)"

		# hides the color scale when no marker exists
		$scope.colorScaleClass = ->
			output = ''
			output += 'color-scale--visible' if dimension > 0
			output += ' color-scale--3d' if dimension is 3
			output

		# determines the dimension of the color scale element
		$scope.colorScaleStyle = -> switch dimension
			when 1
				width: "#{smallWidth}px"
				height: "#{fullWidth}px"
			else
				width: "#{fullWidth}px"
				height: "#{fullWidth}px"

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

		# returns the position style for the indicator
		$scope.indicatorStyle = ->
			output = switch dimension
				when 1 then indicatorStyle1D()
				when 2 then indicatorStyle2D()
				when 3 then indicatorStyle3D()
				else {}
			output['background-color'] = indicatorColor()
			output

		# returns the single colors for the vertices of the 3D coolor scale triangle
		$scope.vertex3DColor = (index) ->
			color = settings.colorMapSingleColors[activeIndices[index]]
			'background-color': if color then color else ''

		$scope.$watchCollection (-> colorScaleIndicator.getIntensities()), (newIntensities) ->
			for intensity, index in newIntensities
				intensities[index] = intensity / 255
			normalizedIntensities = colorScaleIndicator.getNormalizedIntensities()

		$scope.$watchCollection (-> getActiveIndices()), (newActiveIndices) ->
			dimension = newActiveIndices.length
			activeIndices = newActiveIndices
		
		return