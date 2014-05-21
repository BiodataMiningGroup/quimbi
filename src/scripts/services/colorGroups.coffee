# service for managing the color groups
angular.module('quimbi').service 'colorGroups', (ColorGroup, settings) ->

	groups = [
		new ColorGroup settings.singleSelectionSingleColor, 0, settings.singleSelectionColorMap
		new ColorGroup settings.colorMapSingleColors[0], 0, settings.colorMaps[0]
		new ColorGroup settings.colorMapSingleColors[1], 1, settings.colorMaps[1]
		new ColorGroup settings.colorMapSingleColors[2], 2, settings.colorMaps[2]
	]

	@get = (index) -> groups[index]

	return