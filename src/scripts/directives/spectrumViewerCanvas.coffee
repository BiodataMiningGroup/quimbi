# sub-directive to the spectrum viewer
angular.module('quimbi').directive 'spectrumViewerCanvas', ->
	restrict: 'A'

	scope: 
		# data, color
		layer: '=spectrumViewerCanvas'
		# height, width, zoom, left, maximum
		props: '='

	link: (scope, element) ->
		ctx = element[0].getContext '2d'
		drawHeight = drawWidth = drawZoom = drawLeft = heightCoefficient = drawNumber = 0
		drawData = null
		draw = ->
			props = scope.props
			drawColor = scope.layer.color
			drawHeight = props.height
			drawWidth = props.width
			drawZoom = props.zoom
			drawLeft = Math.round props.left / drawZoom
			heightCoefficient = drawHeight / props.maximum
			# number of datapoints to display in the current viewport
			drawNumber = Math.round drawWidth / drawZoom
			drawData = scope.layer.data
			# clear canvas
			ctx.clearRect 0, 0, drawWidth, drawHeight

			# draw spectrum lines
			ctx.beginPath()
			# start from rightmost position
			ctx.moveTo drawWidth, drawHeight - heightCoefficient * drawData[drawLeft + drawNumber]
			while drawNumber--
				ctx.lineTo drawNumber * drawZoom,
					drawHeight - heightCoefficient * drawData[drawLeft + drawNumber]
			ctx.strokeStyle = drawColor
			ctx.stroke()

			# draw measuring points if zoom is high enough
			drawNumber = Math.round drawWidth / drawZoom
			if drawZoom > 5 then while drawNumber--
				ctx.beginPath()
				ctx.arc drawNumber * drawZoom,
					drawHeight - heightCoefficient * drawData[drawLeft + drawNumber], 2, 0, 2*Math.PI
				ctx.fillStyle = drawColor
				ctx.fill()
				
		scope.$watch 'props.width', (width) ->	element[0].width = width
		scope.$watch 'props.height', (height) -> element[0].height = height
		scope.$watch 'props', draw, yes
		scope.$watch 'layer.timestamp', draw
		return