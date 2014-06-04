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

		southWest_2 = L.latLng Math.ceil(-latBound * (1 + input.overlayShiftY * 2)), Math.ceil(-lngBound)
		northEast_2 = L.latLng Math.ceil(latBound), Math.ceil(lngBound * (1 + input.overlayShiftX * 2))
		overlayBounds = L.latLngBounds southWest_2, northEast_2
		# overlayBounds = L.latLngBounds southWest, northEast

		if input.backgroundImage isnt ''
			map.backgroundLayer = L.imageOverlay input.backgroundImage, overlayBounds

		map.canvasLayer = L.canvasOverlay canvas.element[0], maxBounds, opacity: 1.0
		map.self.addLayer map.canvasLayer

		if input.overlayImage isnt ''
			map.overlayLayer = L.imageOverlay input.overlayImage, overlayBounds

		# add control to reduce opacity
		lowerOpacity = new L.Control.lowerOpacity()
		map.self.addControl lowerOpacity
		lowerOpacity.setOpacityLayer map.canvasLayer
		lowerOpacity.setPosition 'bottomleft'

		# add control to increase opacity
		higherOpacity = new L.Control.higherOpacity()
		map.self.addControl higherOpacity
		higherOpacity.setOpacityLayer map.canvasLayer
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
				remove: off
				edit: off
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

		# no apply for this events, because they are executed on ng-click!
		map.self.on 'draw:deleted', (e) ->
			regions.remove stamp for stamp, layer of e.layers._layers

		# update edited regions on the fly
		map.self.on 'draw:editstart', (e) ->
			map.self.on 'mouseup', renderer.updateRegionMask

		map.self.on 'draw:editstop', (e) ->
			map.self.off 'mouseup', renderer.updateRegionMask
			renderer.updateRegionMask()

		return


	controller: ($scope) ->

		# creates a new Leaflet marker from a Marker object
		newLeafletMarkerFrom = (marker) ->
			L.marker marker.getPosition(),
				icon: L.divIcon className: "marker-point marker-point--#{marker.getColor()}"
				draggable: yes

		markerDragging = no

		# synchronizes the Leaflet markers with the list of the markers service
		# don't do it while dragging a marker, because then no 'dragend' event
		# is fired
		syncMarkers = (markerList) -> unless markerDragging
			for leafletMarker in map.markers
				map.self.removeLayer leafletMarker

			map.markers.length = 0

			# don't draw markers, if they are disabled in the settings
			# but remove them in case there are some
			unless settings.showPoints then return

			for marker in markerList when marker.isSet()
				m = newLeafletMarkerFrom marker
				m._index = marker.getIndex()
				m.on 'dragstart', ->	$scope.$apply =>
					markerDragging = yes
					markers.switchOn @_index
					renderer.update()
				m.on 'dragend', -> $scope.$apply ->
					markerDragging = no
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

		# show or hide background layer
		toggleBackground = (show) ->
			if show
				map.self.addLayer map.backgroundLayer
				map.backgroundLayer.bringToBack()
			else
				map.self.removeLayer map.backgroundLayer
		$scope.$watch "settings.showBackground", toggleBackground

		# show or hide overlay layer
		toggleOverlay = (show) ->
			if show
				map.self.addLayer map.overlayLayer
				map.overlayLayer.bringToBack()
				map.canvasLayer.bringToBack()
				map.backgroundLayer.bringToBack()
			else
				map.self.removeLayer map.overlayLayer
		$scope.$watch "settings.showOverlay", toggleOverlay

		# show or hide regular grid
		toggleGrid = (show) ->
			if show
				map.self.addLayer map.gridLayer
			else
				map.self.removeLayer map.gridLayer
		$scope.$watch "settings.showGrid", toggleGrid

		return
