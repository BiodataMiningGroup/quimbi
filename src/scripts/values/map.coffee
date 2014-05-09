# storing the Leaflet map object
angular.module('quimbi').value 'map',

	# the DOM wrapper element of the Leaflet map
	element: null

	# the Leaflet map object
	self: null

	# regular grid on the map
	gridLayer: null

	# the feature group/layer of the Leaflet regions
	drawnItems: L.featureGroup()

	# the Leaflet markers
	markers: []
