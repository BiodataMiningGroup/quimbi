# data structure for storing the combinations of display color, color channel
# index, color map etc.
angular.module('quimbi').factory 'ColorGroup', (colorMap) ->

	class ColorGroup

		constructor: (@_singleColor, @_channelIndex, @_colorMapName) ->

			unless 0 <= @_channelIndex <= 2
				throw new Error 'The channel index must be in the range of [0, 2].'

			unless @_colorMapName in colorMap.getAvailableColorMaps()
				throw new Error "The color map '#{@_colorMapName}' does not exist."

		getSingleColor: -> @_singleColor

		getChannelIndex: -> @_channelIndex

		getColorMapName: -> @_colorMapName

		getColorMap: -> colorMap.get @_colorMapName