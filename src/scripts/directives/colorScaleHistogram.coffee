# directive to display the histogram of a marker if only one is present
angular.module('quimbi').directive 'colorScaleHistogram', (markers, intensityHistogram, ranges, settings, C) ->

	restrict: 'A'

	link: (scope, element) ->
		ctx = element[0].getContext '2d'
		width = element[0].width
		height = element[0].height

		histogram = bounds = null
		boundsStart = boundsEnd = 0
		maximum = drawNumber = widthCoefficient = heightCoefficient = 0

		redrawHistogram = (index) ->
			histogram = intensityHistogram.get()[index]
			bounds = intensityHistogram.getChannelBounds()[index]
			boundsStart = Math.round (1 - bounds.max) * height
			boundsEnd = Math.round (1 - bounds.min) * height
			ctx.fillStyle = 'black'
			ctx.fillRect 0, boundsStart, width, boundsEnd - boundsStart
			ctx.fillStyle = 'white'
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
					redrawHistogram marker.getIndex() if marker

		scope.$on 'renderer.updated', updateHistogram

		# update on initialization
		updateHistogram()
		
		return
