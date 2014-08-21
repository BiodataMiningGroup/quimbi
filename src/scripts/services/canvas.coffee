# service for the main canvas. it creates the canvas element (since it is shared
# between different routes) and manages the downscaling (upscaling is done by css).
# DEV I'm pretty sure down and upscaling are currently both handled by leaflet, leaving the canvas at its initial size all the time
# DEV a quick check showed, that checkScale and getPixelPosition are never called
angular.module('quimbi').service 'canvas', ($document) ->
	# the canvas element
	@element = angular.element $document[0].createElement 'canvas'

	@setSize = (w, h) =>
		@element[0].width = w
		@element[0].height = h

	return
