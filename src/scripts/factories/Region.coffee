# creates a new Region object
angular.module('quimbi').factory 'Region', ->

	class Region

		constructor: (params) ->

			@_layer = params.layer

			@_stamp = "#{L.stamp @_layer}"

			@_pixelCoords = params.pixelCoords

			@_latLngCoords = params.latLngCoords

		getLayer: -> @_layer

		getStamp: -> @_stamp

		getPixelCoords: -> @_pixelCoords

		getLatLngCoords: -> @_latLngCoords
