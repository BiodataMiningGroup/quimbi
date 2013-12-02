# service for the main canvas. it creates the canvas element (since it is shared
# between different routes) and manages the downscaling (upscaling is done by css).
angular.module('quimbi').service 'canvas', ($document) ->
	# original size of the canvas
	width = height = 0

	@element = angular.element $document[0].createElement 'canvas'

	@setOrigSize = (w, h) ->
		height = h
		width = w

	# reduces canvas dimension if user scaling goes below original size
	# this makes webgl rendering more efficiently
	@checkScale = (w) =>
		if w >= width
			@element.width = width
			@element.height = height
		else
			scale = w / width
			@element.width *= scale
			@element.height *= scale

	return