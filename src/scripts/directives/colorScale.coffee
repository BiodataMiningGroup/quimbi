# directive to read a local text file
angular.module('quimbi').directive 'colorScale', (markers, ranges, settings, colorScaleIndicator) ->
	
	restrict: 'A'

	templateUrl: 'templates/colorScale.html'

	replace: yes

	controller: ($scope) ->

		fullWidth = 256
		smallWidth = 30

		intensities = [0, 0, 0, 0]

		activeIndices = []

		dimension = 0

		getActiveIndices = -> switch settings.displayMode
			when 'mean' then ranges.currentGroups()
			else marker.getColorMaskIndex() for marker in markers.getList()

		translateCSS = (x, y) ->
			x = Math.round x
			y = Math.round y
			'transform': "translate(#{x}px,#{y}px)"
			'webkit-transform': "translate(#{x}px,#{y}px)"

		$scope.colorScaleClass = ->
			if dimension > 0 then 'color-scale--visible'
			else ''

		$scope.colorScaleStyle = -> switch dimension
			when 1
				width: "#{smallWidth}px"
				height: "#{fullWidth}px"
			else
				width: "#{fullWidth}px"
				height: "#{fullWidth}px"

		indicatorStyle1D = -> translateCSS smallWidth * 0.5,
			fullWidth * (1-intensities[activeIndices[0]])

		indicatorStyle2D = -> translateCSS fullWidth * (1-intensities[activeIndices[0]]),
			fullWidth * (1-intensities[activeIndices[1]])

		indicatorStyle3D = ->

		$scope.indicatorStyle = -> switch dimension
			when 1 then indicatorStyle1D()
			when 2 then indicatorStyle2D()
			when 3 then indicatorStyle3D()
			else ''			

		$scope.$watchCollection (-> colorScaleIndicator.getIntensities()), (newIntensities) ->
			for intensity, index in newIntensities
				intensities[index] = intensity / 255

		$scope.$watchCollection (-> getActiveIndices()), (newActiveIndices) ->
			dimension = newActiveIndices.length
			activeIndices = newActiveIndices
		
		return