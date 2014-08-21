# service for managing the color groups
angular.module('quimbi').service 'colorGroups', (ColorGroup, settings) ->

	groups = [
		new ColorGroup 0, ColorGroup.TYPE_SINGLE
		new ColorGroup 0, ColorGroup.TYPE_MULTI
		new ColorGroup 1, ColorGroup.TYPE_MULTI
	]

	@get = (index) -> groups[index]

	@getAll = -> groups

	return