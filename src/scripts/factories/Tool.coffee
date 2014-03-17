# tool object with information about the current state of a tool.
angular.module('quimbi').factory 'Tool', (selection, map) ->
	# constructor function for the Tool
	(id, isDefault) ->
		newMarker = (lat=0, lng=0) -> L.marker L.latLng(lat, lng),
			icon: L.divIcon className: "tool-point-#{id}"

		# Leaflet marker object
		marker = newMarker()

		# add marker to map and to markers array
		setMarker = ->	marker.addTo map.self

		# remove marker from map and markers array
		removeMarker = -> map.self.removeLayer marker

		# x, y: position on the canvas in [0,1]
		# lat, lng: position on the canvas in Leaflet coordinates
		@position =
			x: 0
			y: 0
			lat: 0
			lng: 0

		@newPosition = (position) =>
			angular.extend @position, position
			marker.setLatLng L.latLng position.lat, position.lng
			marker.update()

		# tool is currently drawing/selecting
		@drawing = no #yes if isDefault?

		# a selection of this tool is currently visible
		@_passive = no

		Object.defineProperty @, 'passive',
			get: -> @_passive
			set: (x) ->
				if x then setMarker()
				else removeMarker()
				@_passive = x

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
