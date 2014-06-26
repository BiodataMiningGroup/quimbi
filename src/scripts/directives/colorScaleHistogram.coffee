# directive to display the histogram of a marker if only one is present
angular.module('quimbi').directive 'colorScaleHistogram', (markers, colorScaleHistogram, ranges, settings, C) ->

	restrict: 'A'

	link: (scope, element) ->
		ctx = element[0].getContext '2d'
		width = element[0].width
		height = element[0].height
		ctx.fillStyle = 'white'

		redrawHistogram = (index) ->
			histogram = colorScaleHistogram.get()[index]
			maximum = 0
			maximum = value for value in histogram when value > maximum
			drawNumber = histogram.length
			widthCoefficient = width / maximum
			heightCoefficient = height / drawNumber
			while drawNumber
				ctx.fillRect width, histogram.length - drawNumber--,
					-1 * widthCoefficient * histogram[drawNumber], 1

		updateHistogram = ->
			ctx.clearRect 0, 0, width, height
			switch settings.displayMode
				when C.DISPLAY_MODE.DIRECT
					redrawHistogram 0
				when C.DISPLAY_MODE.MEAN
					redrawHistogram ranges.currentGroups()[0]
				else
					marker = markers.getList()[0]
					redrawHistogram marker.getIndex() if marker and marker.isSet()

		scope.$watch (-> markers.getList()[0]), updateHistogram, yes

		scope.$watch (-> ranges.list), updateHistogram, yes

		scope.$on 'displayController.updateHistogram', updateHistogram
		
		return
