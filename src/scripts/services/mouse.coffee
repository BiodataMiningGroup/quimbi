# service for storing mouse properties
angular.module('quimbi').service 'mouse', ->
	# the mouse position on the canvas in [0, 1]
	@position = 
		x: 0
		y: 0
	return