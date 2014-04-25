# directive to read a local text file
angular.module('quimbi').directive 'colorScale', (markers, ranges, settings, colorScaleIndicator) ->
	
	restrict: 'A'

	templateUrl: 'templates/colorScale.html'

	controller: ($scope) ->

		intensities = [0, 0, 0, 0]

		activeIndices = []

		dimension = 0

		getActiveIndices = -> switch settings.displayMode
			when 'mean' then ranges.currentGroups()
			else marker.getColorMaskIndex() for marker in markers.getList()

		$scope.colorScaleClass = -> switch dimension
			when 1 then 'color-scale--1d': yes
			when 2 then 'color-scale--2d': yes
			when 3 then 'color-scale--3d': yes
			else {}

		indicatorStyle1D = ->
			'top': "#{(1-intensities[activeIndices[0]]) * 100}%"

		indicatorStyle2D = ->
			'top': "#{(1-intensities[activeIndices[1]]) * 100}%"
			'left': "#{(1-intensities[activeIndices[0]]) * 100}%"

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