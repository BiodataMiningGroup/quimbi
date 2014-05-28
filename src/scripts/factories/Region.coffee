# creates a new Region object. It is a region of interest on the map, represented
# as a polygon.
angular.module('quimbi').factory 'Region', ->

	class Region

		@count: 0

		constructor: (params) ->

			# Leaflet layer of this region
			@_layer = params.layer

			# unique identifier
			@_stamp = "#{L.stamp @_layer}"

			# vertex positions in pixel coordinates
			@_pixelCoords = params.pixelCoords

			# vertex positions in Leaflet coordinates
			@_latLngCoords = params.latLngCoords

			@_name = "region-#{Region.count++}"

		getLayer: -> @_layer

		getStamp: -> @_stamp

		getPixelCoords: -> @_pixelCoords

		getLatLngCoords: -> @_latLngCoords

		getName: -> @_name

		setName: (name) -> @_name
