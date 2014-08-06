# directive for the canvas wrapper element in the display route.
# this could be just a controller, too, but the map has to be appended to
# the DOM so an "element" is needed.
angular.module('quimbi').directive 'canvasWrapper', (canvas, input, mouse, map, markers, regions, renderer, settings, MSG, $timeout) ->

	restrict: 'A'

	scope: yes

	link: (scope, element) ->

		configureMap = ->
			# add or remove the background layer
			if settings.showBackground and map.backgroundLayer
				unless map.self.hasLayer map.backgroundLayer
					map.self.addLayer map.backgroundLayer
					map.backgroundLayer.bringToBack()
			else
				map.self.removeLayer map.backgroundLayer

			# add or remove overlay layer
			if settings.showOverlay and map.overlayLayer
				unless map.self.hasLayer map.overlayLayer
					map.self.addLayer map.overlayLayer
			else
				map.self.removeLayer map.overlayLayer

			#add or remove the grid layer
			if settings.showGrid and map.gridLayer
				unless map.self.hasLayer map.gridLayer
					map.self.addLayer map.gridLayer
			else
				map.self.removeLayer map.gridLayer

		initializeMap = ->
			# delay of calculations in ms at rapid mousemovement
			moueseMoveDelay = 50

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
			maxBoundsDirections =
				north: maxBounds.getNorth()
				east: maxBounds.getEast()
				south: maxBounds.getSouth()
				west: maxBounds.getWest()

			# TODO: max zoom should depend on ratio between input and screen size
			map.self = L.map map.element[0],
				maxZoom: 10
				minZoom: 0
				crs: L.CRS.Simple
				zoom: 0
				center: [0, 0]

			L.drawLocal.edit.handlers.edit.tooltip.text = MSG.L_DRAW_EDIT_TOOLTIP
			L.drawLocal.edit.handlers.edit.tooltip.subtext = ''

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

			# create background layer
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
				title: MSG.DOWNLOAD_IMAGE
				onClick: (event, buttonElement) ->
					buttonElement.href = canvas.element[0].toDataURL()
					buttonElement.download = 'quimbi_image.png'

			# pass the events through
			map.drawnItems.on 'mousemove', (e) -> map.self.fire 'mousemove', e
			map.drawnItems.on 'click', (e) -> map.self.fire 'click', e

			map.self.fitBounds maxBounds, animate: off

			mousemoveTimeoutPromise = null
			performMousemove = (e) ->
				position = mouse.position
				# TODO refactor, pretty sure we don't really need lat/lng, x/y and dataX/dataY
				position.lat = e.latlng.lat
				position.lng = e.latlng.lng
				position.x = (e.latlng.lng - maxBoundsDirections.west) / (maxBoundsDirections.east - maxBoundsDirections.west)
				position.y = (e.latlng.lat - maxBoundsDirections.north) / (maxBoundsDirections.south - maxBoundsDirections.north)
				newX = Math.floor position.x * input.dataWidth
				newY = Math.floor (1 - position.y) * input.dataHeight
				if position.dataX isnt newX or position.dataY isnt newY
					position.dataX = newX
					position.dataY = newY
					renderer.update()

			map.self.on 'mousemove', (e) ->
				if maxBounds.contains e.latlng
					# use timeout to delay calculation at rapid mouse movement
					# greatly increases performance!
					$timeout.cancel mousemoveTimeoutPromise
					mousemoveTimeoutPromise = $timeout (-> performMousemove(e)), moueseMoveDelay

			map.self.on 'click', (e) -> if maxBounds.contains e.latlng
				if maxBounds.contains e.latlng then scope.$apply ->
					markers.setAt mouse.position
					renderer.update()

			map.self.on 'moveend', (e) ->	map.center = e.target.getCenter()

			map.self.on 'zoomend', (e) -> map.zoom = e.target.getZoom()

			map.self.on 'draw:created', (e) -> scope.$apply ->
				regions.add e.layer, maxBounds

			# update edited regions on the fly
			map.self.on 'draw:editstart', (e) ->
				map.self.on 'mouseup', renderer.updateRegionMask

			map.self.on 'draw:editstop', (e) ->
				map.self.off 'mouseup', renderer.updateRegionMask
				renderer.updateRegionMask()

		if map.element is null
			# if the map doesn't already exist, initialize it
			initializeMap()
		else
			# else, just append it
			element.append map.element

		# re-configure the map either way
		configureMap()
		return


	controller: ($scope) ->

		# creates a new Leaflet marker from a Marker object
		newLeafletMarkerFrom = (marker) ->
			L.marker marker.getPosition(),
				icon: L.divIcon
					className: "marker-point"
					html: "<span style=\"background-color:#{marker.getColor()};\"></span>"
				draggable: yes

		markerDragging = no

		# synchronizes the Leaflet markers with the list of the markers service
		# don't do it while dragging a marker, because then no 'dragend' event
		# is fired
		syncMarkers = -> unless markerDragging

			for leafletMarker in map.markers
				map.self.removeLayer leafletMarker

			map.markers.length = 0

			# don't draw markers, if they are disabled in the settings
			# but remove them in case there are some
			unless settings.showPoints then return

			for marker, index in markers.getListAll() when marker.isSet()
				m = newLeafletMarkerFrom marker
				m._index = index
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

		$scope.$watchCollection markers.getWatchList, syncMarkers

		# synchronize the Leaflet Draw regions with the list of the regions service
		syncRegions = (regionList) ->
			map.drawnItems.clearLayers()
			for region, i in regionList
				layer = region.getLayer()
				map.drawnItems.addLayer layer
			# must be called in watch expression so the region mask is initialized
			# correctly
			renderer.updateRegionMask()

		$scope.$watchCollection regions.getList, syncRegions

		$scope.$on 'displayController.focusRegion', (e, stamp) ->
			map.self.panTo regions.get(stamp).getLatLngCenter(),
				animate: yes

		return
