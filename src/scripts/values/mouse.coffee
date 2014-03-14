# storing mouse properties
angular.module('quimbi').value 'mouse',
	# the mouse position on the canvas in [0, 1]
	position:
		x: 0
		y: 0
		# leaflet coordinates
		lat: 0
		lng: 0