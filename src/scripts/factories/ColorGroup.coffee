# data structure for storing the combinations of display color, color channel
# index, color map etc.
angular.module('quimbi').factory 'ColorGroup', (colorMap, settings) ->

	class ColorGroup

		@TYPE_SINGLE: 'single'
		@TYPE_MULTI: 'multi'

		constructor: (@_channelIndex, @_type) ->

			unless 0 <= @_channelIndex <= 2
				throw new Error 'The channel index must be in the range of [0, 2].'

		getSingleColor: ->
			if @_type is ColorGroup.TYPE_SINGLE then settings.singleSelectionSingleColor
			else settings.colorMapSingleColors[@_channelIndex]

		getChannelIndex: -> @_channelIndex

		getColorMapName: ->
			if @_type is ColorGroup.TYPE_SINGLE then settings.singleSelectionColorMap
			else settings.colorMaps[@_channelIndex]

		getColorMap: -> colorMap.get @getColorMapName()

		getType: -> @_type