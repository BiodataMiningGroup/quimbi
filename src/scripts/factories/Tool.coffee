# tool object with information about the current state of a tool.
angular.module('quimbi').factory 'Tool', (selection) ->
	# constructor function for the Tool
	(id, isDefault) ->
		# position on the canvas in [0,1]
		@position = x: 0, y: 0

		@toolpoint = L.marker L.latLng(0, 0), { icon: L.divIcon { className: 'tool-point-' + id } }
		# tool is currently drawing/selecting
		@drawing = no #yes if isDefault?
		# a selection of this tool is currently visible
		@passive = no
		# the id/color of this tool
		@id = id
		# is this the default tool?
		@isDefault = isDefault
		# SelectionData of the current selection of this tool
		@selection = null
		# make a new selection on the current position
		@makeSelection = => @selection = selection.make @position
		return
