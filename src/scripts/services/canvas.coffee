# service for the main canvas. it creates the canvas element (since it is shared
# between different routes) and manages the downscaling (upscaling is done by css).
# DEV I'm pretty sure down and upscaling are currently both handled by leaflet, leaving the canvas at its initial size all the time
# DEV a quick check showed, that checkScale and getPixelPosition are never called
angular.module('quimbi').service 'canvas', ($document, shader) ->
	# the canvas element
	@element = angular.element $document[0].createElement 'canvas'
	element = @element[0]
	# original size of the canvas
	width = height = 0

	@setOrigSize = (w, h) ->
		width = element.width = w
		height = element.height = h

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
				glmvilib.render shader.getFinal()
		else
			scale = w / width
			element.width = width * scale
			element.height = height * scale
			glmvilib.render shader.getFinal()

	# returns the pixel position of relative coordinates (in [0, 1])
	@getPixelPosition = (x, y) ->
		x: Math.floor x * width
		y: Math.floor y * height

	return
