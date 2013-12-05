# service for the main canvas. it creates the canvas element (since it is shared
# between different routes) and manages the downscaling (upscaling is done by css).
angular.module('quimbi').service 'canvas', ($document, toolset) ->
	# the canvas element
	@element = angular.element $document[0].createElement 'canvas'
	element = @element[0]
	# original size of the canvas
	width = height = 0

	@setOrigSize = (w, h) ->
		height = h
		width = w

	# reduces canvas dimension if user scaling goes below original size
	# this makes webgl rendering more efficiently
	@checkScale = (w) =>
		if w > width
			# make sure the canvas is at its original size again
			# if it is, do nothing
			if element.width isnt width or element.height isnt height
				element.width = width
				element.height = height
				# render once because changing the size clears the canvas
				mvi.renderOnce toolset.getRenderState()
		else
			scale = w / width
			element.width = width * scale
			element.height = height * scale
			mvi.renderOnce toolset.getRenderState()

	# returns the pixel position of relative coordinates (in [0, 1])
	@getPixelPosition = (x, y) ->
		x: Math.round x * width
		y: Math.round y * height

	return