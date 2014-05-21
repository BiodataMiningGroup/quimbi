# object that has a color group assigned to it
angular.module('quimbi').factory 'ColorGroupObject', ->

	class ColorGroupObject

		constructor: (@_colorGroup) ->

		getColor: -> @_colorGroup.getSingleColor()

		getIndex: -> @_colorGroup.getChannelIndex()

		setColorGroup: (colorGroup) -> @_colorGroup = colorGroup