# directive for the canvas wrapper element in the display route.
# this could be just a controller, too, but the canvas has to be appended to
# the DOM so an "element" is needed.
angular.module('quimbi').directive 'canvasWrapper', (canvas, mouse, map, markers, regions, renderer, settings) ->

	restrict: 'A'

	scope: yes

	link: (scope, element) ->
		inputWidth = canvas.element[0].width
		inputHeight = canvas.element[0].height

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
		map.self.setMaxBounds maxBounds

		# add scale with total object width in um
		L.control.microScale(objectWidth: 80000).addTo map.self

		map.self.addLayer L.canvasOverlay canvas.element[0], maxBounds

		map.self.addLayer L.graticule
			interval: inputPixelWidth
			southWest: southWest
			northEast: northEast
			clickable: no

		#TODO use image of input data set
		#TODO
		# image2 = L.imageOverlay 'data/image_small.png', maxBounds
		# minimap = L.control.minimap()
		# minimap.initialize image2,
		# 	zoomLevelFixed: 0
		# 	width: inputWidth
		# 	height: inputHeight
		# 	toggleDisplay: on
		# minimap.addTo map.self

		map.self.addLayer scope.drawnItems

		# initialise the draw control and pass it the FeatureGroup of editable layers		
		map.self.addControl new L.Control.Draw
			edit:
				featureGroup: scope.drawnItems
			draw:
				# disable all leaflet dawing tools but rectangle and polygon
				polyline: off
				circle: off
				marker: off
				rectangle: shapeOptions:
					color: 'white'
					fill: no
					weight: 2
				polygon: shapeOptions:
					color: 'white'
					fill: no
					weight: 2

		# don't fit bounds if map state/viewport is already manually changed
		map.self.fitBounds maxBounds, animate: off unless map.dirty()

		applyLeafletPosition = (e, position) ->
			position.lat = e.latlng.lat
			position.lng = e.latlng.lng
			position.x = (e.latlng.lng - maxBounds.getWest()) /
				(maxBounds.getEast() - maxBounds.getWest())
			position.y = (e.latlng.lat - maxBounds.getNorth()) /
				(maxBounds.getSouth() - maxBounds.getNorth())
			position

		map.self.on 'mousemove', (e) ->
			if maxBounds.contains e.latlng then scope.$apply ->
				applyLeafletPosition e, mouse.position


		map.self.on 'click', (e) -> if maxBounds.contains e.latlng
			scope.$apply ->
				markers.setAt mouse.position
				renderer.update()

		map.self.on 'moveend', (e) ->	map.center = e.target.getCenter()

		map.self.on 'zoomend', (e) -> map.zoom = e.target.getZoom()

		map.self.on 'draw:created', (e) -> scope.$apply ->
			regions.add e.layer, maxBounds
			renderer.updateRegionMask()

		map.self.on 'draw:deleted', (e) -> scope.$apply ->
			regions.remove stamp for stamp, layer of e.layers._layers
			renderer.updateRegionMask()

		map.self.on 'draw:edited', (e) -> scope.$apply ->
			for stamp, layer of e.layers._layers
				regions.remove stamp
				regions.add layer, maxBounds
			renderer.updateRegionMask()

		map.self.on 'draw:drawstart draw:editstart draw:deletestart', (e) ->
			scope.$apply regions.setActive

		map.self.on 'draw:drawstop draw:editstop draw:deletestop', (e) ->
			scope.$apply regions.setInactive

		return


	controller: ($scope) ->
		leafletMarkers = []

		newLeafletMarkerFrom = (marker) ->
			L.marker marker.getPosition(),
				icon: L.divIcon className: "marker-point marker-point--#{marker.getColor()}"
				draggable: yes

		syncMarkers = (markerList) ->
			for leafletMarker in leafletMarkers
				map.self.removeLayer leafletMarker

			leafletMarkers.length = 0
				
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
			$scope.$watch (-> markers.getList()), syncMarkers, yes

		# adding leaflet.draw toolbar and a layer to enable region selection
		# initialise the FeatureGroup to store editable layers
		$scope.drawnItems = L.featureGroup()

		leafletRegions = []

		syncRegions = (regionList) ->
			$scope.drawnItems.clearLayers()
			leafletRegions.length = 0
			for region, i in regionList
				layer = region.getLayer()
				$scope.drawnItems.addLayer layer
				leafletMarkers.push layer

		$scope.$watchCollection (-> regions.getList()), syncRegions

		return
