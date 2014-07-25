# creates a new Region object. It is a region of interest on the map, represented
# as a polygon.
angular.module('quimbi').factory 'Region', (map, input) ->

	class Region

		@count: 0

		constructor: (@_layer, @_maxBounds) ->

			# own fature group and edit toolbar to allow editing of single
			# regions (Leaflet.Draw allows only editing of everything at once)
			@_featureGroup = L.featureGroup()

			@_featureGroup.addLayer @_layer

			@_editToolbar = new L.EditToolbar.Edit map.self,
				featureGroup: @_featureGroup
				selectedPathOptions: {}

			# unique identifier
			@_stamp = "#{L.stamp @_layer}"

			@_name = "region-#{Region.count++}"

			@_active = yes

		_latLngsToPixelCoords: (latLngs) ->
			pixelCoords = []
			maxLng = @_maxBounds.getWest()
			maxLat = @_maxBounds.getNorth()
			boundsWidth = @_maxBounds.getEast() - maxLng
			boundsHeight = @_maxBounds.getSouth() - maxLat
			canvasWidth = input.dataWidth
			canvasHeight = input.dataHeight

			for latLng in latLngs
				x = Math.round (latLng.lng - maxLng) / boundsWidth * canvasWidth
				y = Math.round (latLng.lat - maxLat) / boundsHeight * canvasHeight
				pixelCoords.push L.point(x, y)

			pixelCoords

		setActive: -> @_active = yes

		setInactive: -> @_active = no

		isActive: -> @_active

		getLayer: -> @_layer

		getStamp: -> @_stamp

		getPixelCoords: -> @_latLngsToPixelCoords @getLatLngCoords()

		getLatLngCoords: -> @_layer.getLatLngs()

		getLatLngCenter: =>
			latLngs = @getLatLngCoords()
			L.latLng (latLngs[0].lat + latLngs[1].lat) / 2,
				(latLngs[0].lng + latLngs[2].lng) / 2

		getName: -> @_name

		setName: (name) -> @_name

		editToolbar: -> @_editToolbar
