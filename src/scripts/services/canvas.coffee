angular.module('quimbi').service 'canvas', ($document) ->
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