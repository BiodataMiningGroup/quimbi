# storing the Leaflet map object
angular.module('quimbi').value 'map',
	# the actual map is a property of this value and not the value itself
	# so the reference to it is always correct
	self: null

	# regular grid on the map
	gridLayer: null

	# the following properties are for creating a new map in the same state of
	# the old map (e.g. when the views have switched)

	# zoom value
	zoom: null
	# viewport position
	center: null
	# check if map state has changed
	dirty: -> @zoom? or @center?
