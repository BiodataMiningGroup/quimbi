# tool object with information about the current state of a tool.
angular.module('quimbi').factory 'Tool', ($rootScope, selection, map, settings) ->
	# draw and drawn functions are from toolset for Leaflet events
	# can't inject toolset because of circular dependency
	(id, isDefault, draw, drawn) ->

		newMarker = (lat=0, lng=0) =>
			m = L.marker L.latLng(lat, lng),
				icon: L.divIcon className: "tool-point-#{id}"
				draggable: yes
			m.on 'dragstart', =>
				@dragging = yes
				draw @id
			m.on 'dragend', =>
				@dragging = no
				$rootScope.$apply drawn
			m

		# Leaflet marker object
		marker = newMarker()

		# add marker to map if markers are to be shown
		setMarker = ->	if settings.showPoints
			marker.addTo map.self

		# remove marker from map and markers array
		removeMarker = -> map.self.removeLayer marker

		@newPosition = (position) =>
			angular.extend @position, position
			marker.setLatLng L.latLng position.lat, position.lng
			marker.update()

		# x, y: position on the canvas in [0,1]
		# lat, lng: position on the canvas in Leaflet coordinates
		@position =
			x: 0
			y: 0
			lat: 0
			lng: 0

		# tool is currently drawing/selecting
		@drawing = no #yes if isDefault?

		# tool is currently dragged
		@dragging = no

		# a selection of this tool is currently visible
		@_passive = no

		Object.defineProperty @, 'passive',
			get: -> @_passive
			set: (passive) ->
				@_passive = passive
				if passive then setMarker()
				else if not @dragging then removeMarker()

		# the id/color of this tool
		@id = id

		# is this the default tool?
		@isDefault = isDefault

		# SelectionData of the current selection of this tool
		@selection = null

		# make a new selection on the current position
		@makeSelection = -> @selection = selection.make @position

		# creates a new marker to be added to a newly created map
		# (the old marker gets destroyed along with the old map)
		@recreate = ->
			marker = newMarker @position.lat, @position.lng
			setMarker() if @passive

		return
