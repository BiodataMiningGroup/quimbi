# storing mouse properties
angular.module('quimbi').value 'mouse',
	position:
        # the mouse position on the canvas in [0, 1]
		x: 0
		y: 0
		# leaflet coordinates
		lat: 0
		lng: 0

		dataX: 0
		dataY: 0
