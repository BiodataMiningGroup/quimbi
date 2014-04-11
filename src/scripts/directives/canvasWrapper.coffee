# directive for the canvas wrapper element in the display route.
# this could be just a controller, too, but the canvas has to be appended to
# the DOM so an "element" is needed.
angular.module('quimbi').directive 'canvasWrapper', (canvas, mouse, map, markers, renderer, settings) ->

	restrict: 'A'

	scope: yes

	link: (scope, element) ->
		inputWidth = canvas.element[0].width
		inputHeight = canvas.element[0].height

		leafletMarkers = []

		# TODO: max zoom should depend on ratio between input and screen size
		map.self = L.map element[0],
			maxZoom: 10
			minZoom: 0
			crs: L.CRS.Simple
			# if the map is re-created (e.g. after switching views) this initializes
			# the map to its old viewport
			zoom: map.zoom or 0
			center: map.center or [0, 0]

		# projection should not repeat itself (also getProjectionBounds and
		# getPixelWorldBounds don't work without it)
		map.self.options.crs.infinite = no

		#console.log inputWidth, inputHeight

		shapeFactor = inputWidth / inputHeight
		if shapeFactor >= 2
			lngBound = 180
			latBound = 180 / shapeFactor
		else
			lngBound = 90 * shapeFactor
			latBound = 90

		inputPixelWidth = lngBound * 2 / inputWidth

		# setup matching LatLng bounds for the input dimensions
		southWest = L.latLng Math.ceil(-latBound), Math.ceil(-lngBound)
		northEast = L.latLng Math.ceil(latBound), Math.ceil(lngBound)
		# alternatively: set maxBounds on map.self options
		maxBounds = new L.LatLngBounds southWest, northEast
		map.self.setMaxBounds maxBounds

		applyLeafletPosition = (e, position) ->
			position.lat = e.latlng.lat
			position.lng = e.latlng.lng
			position.x = (e.latlng.lng - maxBounds.getWest()) /
				(maxBounds.getEast() - maxBounds.getWest())
			position.y = (e.latlng.lat - maxBounds.getNorth()) /
				(maxBounds.getSouth() - maxBounds.getNorth())
			position

		# add scale with total object width in um
		L.control.microScale(objectWidth: 80000).addTo map.self

		map.self.addLayer L.canvasOverlay canvas.element[0], maxBounds

		map.self.addLayer L.graticule
			interval: inputPixelWidth
			southWest: southWest
			northEast: northEast
			clickable: no

		# image2 = L.imageOverlay 'data/image.png', maxBounds
		# minimap = new L.Control.Minimap.self(image2).addTo(map.self);

		# don't fit bounds if map state/viewport is already manually changed
		map.self.fitBounds maxBounds, animate: false unless map.dirty()

		map.self.on 'mousemove', (e) ->
			if maxBounds.contains e.latlng then scope.$apply ->
				applyLeafletPosition e, mouse.position


		map.self.on 'click', (e) -> if maxBounds.contains e.latlng
			scope.$apply ->
				markers.setAt mouse.position
				renderer.update()

		map.self.on 'moveend', (e) ->	map.center = e.target.getCenter()

		map.self.on 'zoomend', (e) -> map.zoom = e.target.getZoom()

		newLeafletMarkerFrom = (marker) ->
			L.marker marker.getPosition(),
				icon: L.divIcon className: "marker-point marker-point--#{marker.getColor()}"
				draggable: yes

		syncMarkers = (markerList) ->
			for leafletMarker in leafletMarkers
				map.self.removeLayer leafletMarker
				
			for marker, i in markerList when marker.isSet()
				m = newLeafletMarkerFrom marker
				index = i
				m.on 'dragstart', ->	scope.$apply ->
					markers.activate index
					renderer.update()
				m.on 'dragend', -> scope.$apply ->
					markers.setAt mouse.position
					renderer.update()

				m.addTo map.self
				leafletMarkers.push m

		if settings.showPoints
			scope.$watch (-> markers.getList()), syncMarkers, yes

		return

		
