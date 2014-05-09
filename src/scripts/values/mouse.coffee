# storing mouse properties
angular.module('quimbi').value 'mouse',
	position:
      	# the mouse position on the canvas in [0, 1]
		x: 0
		y: 0
		# leaflet coordinates
		lat: 0
		lng: 0
		# the mouse mosition in data-grid coordinates
		dataX: 0
		dataY: 0
