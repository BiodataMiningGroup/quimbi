# directive for the canvas wrapper element in the display route.
# this could be just a controller, too, but the canvas has to be appended to
# the DOM so an "element" is needed.
angular.module('quimbi').directive 'canvasWrapper', (canvas, toolset, mouse, map) ->

	restrict: 'A'

	scope: yes

	link: (scope, element) ->
		inputWidth = canvas.element[0].width
		inputHeight = canvas.element[0].height

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

		inputPixelWidth = lngBound * 2 / inputWidth
		#console.log "iPW", inputPixelWidth

		# widthBound = inputWidth/2
		# heightBound = inputHeight/2

		# setup matching LatLng bounds for the input dimensions
		# southWest = map.self.unproject([Math.ceil(-widthBound), Math.ceil(-heightBound)], 5) #map.self.getMaxZoom())
		# northEast = map.self.unproject([Math.ceil(widthBound), Math.ceil(heightBound)], 5) #map.self.getMaxZoom())
		southWest = L.latLng Math.ceil(-latBound), Math.ceil(-lngBound)
		northEast = L.latLng Math.ceil(latBound), Math.ceil(lngBound)
		# alternatively: set maxBounds on map.self options
		maxBounds = new L.LatLngBounds southWest, northEast
		map.self.setMaxBounds maxBounds

		# add scale with total object width in um
		map.self.addLayer L.control.microScale objectWidth: 80000

		map.self.addLayer L.canvasOverlay canvas.element[0], maxBounds

		map.self.addLayer L.graticule
			interval: inputPixelWidth
			southWest: southWest
			northEast: northEast
			clickable: no
		
		# image2 = L.imageOverlay 'data/image.png', maxBounds
		# minimap = new L.Control.Minimap.self(image2).addTo(map.self);

		# fit bounds and setting max bounds should happen in the initialization of
		# map.self to avoid initial animation. padding makes sure that there is
		# additional space around the image that can be covered by controls

		# don't fit bounds if map state/viewport is already manually changed
		map.self.fitBounds maxBounds, padding: [100, 100] unless map.dirty()

		map.self.on 'mousemove', (e) ->
			if maxBounds.contains e.latlng then scope.$apply ->
				mouse.position.lat = e.latlng.lat
				mouse.position.lng = e.latlng.lng
				mouse.position.x = (e.latlng.lng - maxBounds.getWest()) /
					(maxBounds.getEast() - maxBounds.getWest())
				mouse.position.y = (e.latlng.lat - maxBounds.getNorth()) /
					(maxBounds.getSouth() - maxBounds.getNorth())


		map.self.on 'click', (e) -> if maxBounds.contains e.latlng
			scope.$apply -> if toolset.drawing()
				toolset.drawn mouse.position

		map.self.on 'moveend', (e) ->	map.center = e.target.getCenter()

		map.self.on 'zoomend', (e) -> map.zoom = e.target.getZoom()

		return