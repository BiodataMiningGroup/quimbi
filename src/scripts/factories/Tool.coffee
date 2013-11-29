angular.module('quimbi').factory 'Tool', ->
	(id, isDefault) ->
		@drawing = no #yes if isDefault?
		@passive = no
		@id = id
		@isDefault = isDefault
		@position = _x: 0, _y: 0
		Object.defineProperty @position, 'x', 
			set: (val) -> @_x = val
			get: -> "#{@_x * 100}%"
		Object.defineProperty @position, 'y', 
			set: (val) -> @_y = val
			get: -> "#{@_y * 100}%"
		return