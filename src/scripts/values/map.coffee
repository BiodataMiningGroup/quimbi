# storing the Leaflet map object
angular.module('quimbi').value 'map',

	# the DOM wrapper element of the Leaflet map
	element: null

	# the Leaflet map object
	self: null

	# layer for main canvas
	canvasLayer: null

	# layer for background image
	backgroundLayer: null

	# layer for overlay image (or foreground image)
	overlayLayer: null

	# regular grid on the map
	gridLayer: null

	# the feature group/layer of the Leaflet regions
	drawnItems: L.featureGroup()

	# the Leaflet markers
	markers: []
