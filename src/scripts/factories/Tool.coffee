# tool object with information about the current state of a tool.
angular.module('quimbi').factory 'Tool', ($rootScope, selection, map, settings) ->
	
	class Tool

		###
		@param {number} id The ID/color of this tool
		@param {boolean} isDefault Is this the default tool?
		@param {function} _draw Callback that invokes drawing with a tool.
		@param {function} _drawn Callback that finished drawing with a tool.
		@constructor
		@return {object} A new Tool object.
		###
		constructor: (@id, @isDefault, @_draw, @_drawn) ->

			# Leaflet marker object
			@_marker = @newMarker()

			# a selection of this tool is currently visible
			@_passive = no

			# tool is currently dragged
			@_dragging = no

			# x, y: position on the canvas in [0,1]
			# lat, lng: position on the canvas in Leaflet coordinates
			@position =
				x: 0.5
				y: 0.5
				lat: 0
				lng: 0

			# tool is currently drawing/selecting
			@drawing = no

			# SelectionData of the current selection of this tool
			@selection = null

			Object.defineProperty @, 'passive',
				get: -> @_passive
				set: (passive) ->
					@_passive = passive
					if passive then @setMarker()
					else if not @_dragging then @removeMarker()

			Tool.groups.push @id unless @id in Tool.groups
			Tool.defaultGroup = @id if @isDefault

		# the ids of all registered tools
		@groups: []

		@defaultGroup: ''

		newMarker: (lat=0, lng=0) ->

			m = L.marker L.latLng(lat, lng),
				icon: L.divIcon className: "tool-point-#{@id}"
				draggable: yes

			m.on 'dragstart', =>
				@_dragging = yes
				$rootScope.$apply @_draw @id

			m.on 'dragend', =>
				@_dragging = no
				$rootScope.$apply @_drawn

			m

		# add marker to map if markers are to be shown
		setMarker: -> if settings.showPoints then @_marker.addTo map.self

		# remove marker from map and markers array
		removeMarker: -> map.self.removeLayer @_marker

		newPosition: (position) ->
			angular.extend @position, position
			@_marker.setLatLng L.latLng position.lat, position.lng
			@_marker.update()

		# make a new selection on the current position
		makeSelection: -> @selection = selection.make @position

		# creates a new marker to be added to a newly created map
		# (the old marker gets destroyed along with the old map)
		recreate: ->
			@_marker = @newMarker @position.lat, @position.lng
			@setMarker() if @passive
