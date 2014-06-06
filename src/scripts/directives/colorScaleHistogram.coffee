# directive to display the histogram of a marker if only one is present
angular.module('quimbi').directive 'colorScaleHistogram', (markers, colorScaleHistogram, regions, ranges) ->

	restrict: 'A'

	link: (scope, element) ->
		ctx = element[0].getContext '2d'
		width = element[0].width
		height = element[0].height
		ctx.fillStyle = 'white'

		redrawHistogram = (marker) ->
			histogram = colorScaleHistogram.get()[marker.getIndex()]
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
			marker = markers.getList()[0]
			unless marker is undefined
				redrawHistogram marker if marker.isSet() or marker.getType() is 'mean'

		scope.$watch (-> markers.getList()[0]), updateHistogram, yes

		scope.$watch (-> ranges.list), updateHistogram, yes

		scope.$on 'displayController.updateHistogram', updateHistogram
		
		return
