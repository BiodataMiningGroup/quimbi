# tool object with information about the current state of a tool.
angular.module('quimbi').factory 'Tool', ->
	# constructor function for the Tool
	(id, isDefault) ->
		@toolpoint = undefined
		# tool is currently drawing/selecting
		@drawing = no #yes if isDefault?
		# a selection of this tool is currently visible
		@passive = no
		# the id/color of this tool
		@id = id
		# is this the default tool?
		@isDefault = isDefault
		# the current position of the selection of this tool
		@position = _x: 0, _y: 0
		# return the position formatted as string for css
		Object.defineProperty @position, 'x',
			set: (val) -> @_x = val
			get: -> "#{@_x * 100}%"
		Object.defineProperty @position, 'y',
			set: (val) -> @_y = val
			get: -> "#{@_y * 100}%"
		return
