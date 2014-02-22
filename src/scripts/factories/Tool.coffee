# tool object with information about the current state of a tool.
angular.module('quimbi').factory 'Tool', ->
	# constructor function for the Tool
	(id, isDefault) ->
		@toolpoint = L.marker L.latLng(0, 0), { icon: L.divIcon { className: 'tool-point-' + id } }
		# tool is currently drawing/selecting
		@drawing = no #yes if isDefault?
		# a selection of this tool is currently visible
		@passive = no
		# the id/color of this tool
		@id = id
		# is this the default tool?
		@isDefault = isDefault


		return
