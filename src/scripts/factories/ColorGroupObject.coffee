# object that has a color group assigned to it
angular.module('quimbi').factory 'ColorGroupObject', ->

	class ColorGroupObject

		constructor: (@_colorGroup) ->

		getColor: -> @_colorGroup.getSingleColor()

		getIndex: -> @_colorGroup.getChannelIndex()

		getType: -> @_colorGroup.getType()

		getColorMapName: -> @_colorGroup.getColorMapName()

		setColorGroup: (colorGroup) -> @_colorGroup = colorGroup