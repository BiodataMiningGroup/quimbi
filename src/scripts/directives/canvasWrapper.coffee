# directive for the canvas wrapper element in the display route.
# this could be just a controller, too, but the map has to be appended to
# the DOM so an "element" is needed.
angular.module('quimbi').directive 'canvasWrapper', (canvas, input, mouse, map, markers, regions, renderer, settings) ->

	restrict: 'A'

	scope: yes

	link: (scope, element) ->
		# if the map element already exists, just append it
		unless map.element is null
			element.append map.element
			return

		# otherwise initiate the Leaflet map and create the new map element
		map.element = angular.element '<div></div>'
		element.append map.element

		inputWidth = input.width
		inputHeight = input.height

		shapeFactor = inputWidth / inputHeight
		if shapeFactor >= 2
			lngBound = 180
			latBound = 180 / shapeFactor
		else
			lngBound = 90 * shapeFactor
			latBound = 90

		# setup matching LatLng bounds for the input dimensions
		southWest = L.latLng Math.ceil(-latBound), Math.ceil(-lngBound)
		northEast = L.latLng Math.ceil(latBound), Math.ceil(lngBound)
		# alternatively: set maxBounds on map.self options
		maxBounds = new L.LatLngBounds southWest, northEast

		# TODO: max zoom should depend on ratio between input and screen size
		map.self = L.map map.element[0],
			maxZoom: 10
			minZoom: 0
			crs: L.CRS.Simple
			zoom: 0
			center: [0, 0]

		# projection should not repeat itself (also getProjectionBounds and
		# getPixelWorldBounds don't work without it)
		map.self.options.crs.infinite = no
		map.self.setMaxBounds maxBounds

		# add scale with total object width in um
		# TODO dynamic size depends on the input dataset
		L.control.microScale(objectWidth: 80000).addTo map.self

		southWest_2 = L.latLng Math.ceil(-latBound * 1.2), Math.ceil(-lngBound)
		northEast_2 = L.latLng Math.ceil(latBound), Math.ceil(lngBound * 1.064)
		overlayBounds = L.latLngBounds southWest_2, northEast_2
		# overlayBounds = L.latLngBounds southWest, northEast

		canvasLayer = L.canvasOverlay canvas.element[0], maxBounds, opacity: 1.0 #0.8 #1.0 #
		map.self.addLayer canvasLayer

		overlayLayer = L.imageOverlay input.overlayImage, overlayBounds
		if input.overlayImage isnt ''
			map.self.addLayer overlayLayer

		# if input.overlayImage isnt ''
		# 	map.self.addLayer L.imageOverlay input.overlayImage, overlayBounds

		higherOpacity = new L.Control.higherOpacity()
		lowerOpacity = new L.Control.lowerOpacity()
		map.self.addControl lowerOpacity
		map.self.addControl higherOpacity
		higherOpacity.setOpacityLayer overlayLayer
		lowerOpacity.setOpacityLayer overlayLayer
		lowerOpacity.setPosition 'bottomleft'
		higherOpacity.setPosition 'bottomleft'





		inputPixelWidth = lngBound * 2 / input.dataWidth

		map.gridLayer = L.graticule
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

		map.self.addLayer map.drawnItems

		# initialise the draw control and pass it the FeatureGroup of editable layers
		map.self.addControl new L.Control.Draw
			edit:
				featureGroup: map.drawnItems
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

		# add the download canvas button
		map.self.addControl new L.Control.Button
			text: '<i class="icon-download-alt"></i>'
			title: 'Download the image.'
			onClick: (event, buttonElement) ->
				buttonElement.href = canvas.element[0].toDataURL()
				buttonElement.download = 'quimbi_image.png'

		# pass the events through
		map.drawnItems.on 'mousemove', (e) -> map.self.fire 'mousemove', e
		map.drawnItems.on 'click', (e) -> map.self.fire 'click', e

		map.self.fitBounds maxBounds, animate: off

		map.self.on 'mousemove', (e) ->
			if (maxBounds.contains e.latlng) and (regions.contain e.latlng) then scope.$apply ->
				# TODO refactor, pretty sure we don't really need lat/lng, x/y and dataX/dataY
				mouse.position.lat = e.latlng.lat
				mouse.position.lng = e.latlng.lng
				mouse.position.x = (e.latlng.lng - maxBounds.getWest()) / (maxBounds.getEast() - maxBounds.getWest())
				mouse.position.y = (e.latlng.lat - maxBounds.getNorth()) / (maxBounds.getSouth() - maxBounds.getNorth())
				newX = Math.floor mouse.position.x * input.dataWidth
				newY = Math.floor (1 - mouse.position.y) * input.dataHeight
				if mouse.position.dataX isnt newX or mouse.position.dataY isnt newY
					mouse.position.dataX = newX
					mouse.position.dataY = newY
					renderer.update()

		map.self.on 'click', (e) -> if maxBounds.contains e.latlng
			if (maxBounds.contains e.latlng) and (regions.contain e.latlng) then scope.$apply ->
				markers.setAt mouse.position
				renderer.update()

		map.self.on 'moveend', (e) ->	map.center = e.target.getCenter()

		map.self.on 'zoomend', (e) -> map.zoom = e.target.getZoom()

		map.self.on 'draw:created', (e) -> scope.$apply ->
			regions.add e.layer, maxBounds

		map.self.on 'draw:deleted', (e) -> scope.$apply ->
			regions.remove stamp for stamp, layer of e.layers._layers

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

		# creates a new Leaflet marker from a Marker object
		newLeafletMarkerFrom = (marker) ->
			L.marker marker.getPosition(),
				icon: L.divIcon className: "marker-point marker-point--#{marker.getColor()}"
				draggable: yes

		# synchronizes the Leaflet markers with the list of the markers service
		syncMarkers = (markerList) ->
			for leafletMarker in map.markers
				map.self.removeLayer leafletMarker

			map.markers.length = 0

			# don't draw markers, if they are disabled in the settings
			unless settings.showPoints then return

			for marker, i in markerList when marker.isSet()
				m = newLeafletMarkerFrom marker
				index = i
				m.on 'dragstart', ->	$scope.$apply ->
					markers.activate index
					renderer.update()
				m.on 'dragend', -> $scope.$apply ->
					markers.setAt mouse.position
					renderer.update()

				m.addTo map.self
				map.markers.push m

		$scope.$watch (-> markers.getList()), syncMarkers, yes

		# synchronize the Leaflet Draw regions with the list of the regions service
		syncRegions = (regionList) ->
			map.drawnItems.clearLayers()
			for region, i in regionList
				layer = region.getLayer()
				map.drawnItems.addLayer layer
			renderer.updateRegionMask()

		$scope.$watchCollection (-> regions.getList()), syncRegions

		# show or hide regular grid according to the settings
		toogleGrid = (showGrid) ->
			if showGrid
				map.self.addLayer map.gridLayer
			else
				map.self.removeLayer map.gridLayer

		$scope.$watch "settings.showGrid", toogleGrid

		return
