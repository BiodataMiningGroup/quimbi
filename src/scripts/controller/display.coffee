# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, input, settings, renderer, markers, ranges, regions, C) ->

	$scope.C = C

	# array to apply the color map for the single selection to all three color
	# channels
	singleSelectionColorMaps = [
		settings.singleSelectionColorMap
		settings.singleSelectionColorMap
		settings.singleSelectionColorMap
	]

	$scope.settings = settings

	$scope.spectrum =
		layers: []
		labels: input.channelNames
		maximum: 255
		minimum: 0
		length: input.channels

	$scope.spectrumRanges = ranges.list

	$scope.mapRegions = regions.getListAll

	# updates the spectrograms of the different selections to display in the
	# spectrum viewer
	updateSelections = ->
		selections = markers.getSelectionData()
		layers = $scope.spectrum.layers
		layers.length = selections.length
		for selection, index in selections
			if not layers[index]? then layers[index] = {}
			layers[index].color = selection.color
			layers[index].data = selection.data.spectrogram
			# add timestamp, too, to check for spectrum update efficiently
			layers[index].timestamp = Date.now()

	# returns the list of colorGroupObjects that determines the colorMaps
	# according to the current display mode
	getCurrentList = -> switch settings.displayMode
		when C.DISPLAY_MODE.MEAN then ranges.getActive()
		else markers.getList()

	getCurrentWatchList = -> switch settings.displayMode
		when C.DISPLAY_MODE.MEAN then ranges.getWatchList()
		else markers.getWatchList()

	$scope.showColorScale = -> settings.showColorScale

	$scope.$watchCollection markers.getWatchList, updateSelections

	$scope.$watchCollection ranges.getWatchList, renderer.updateChannelMask

	updateActiveColorMaps = ->
		# clear the array
		for i in [0...settings.activeColorMaps.length]
			settings.activeColorMaps[i] = null
		# refill the array
		for colorGroupObject in getCurrentList()
			settings.activeColorMaps[colorGroupObject.getIndex()] =
				colorGroupObject.getColorMapName()
		renderer.updateColorMaps()
		renderer.update()

	$scope.$watchCollection getCurrentWatchList, updateActiveColorMaps

	$scope.$watch 'settings.displayMode', (displayMode) ->
		renderer.updateChannelMask()
		renderer.updateFinal()

		unless markers.getList()[0]?.isSet()
			# activate first marker when switching display modes if it isn't already set
			markers.switchOn 0
		else
			# else prevent the active state of the first marker to leak to the other
			# display mode
			markers.deactivate()

	# reflect event from rangeListItem to spectrumViewer
	$scope.$on 'rangeListItem.focusRange', (e, index) ->
		$scope.$broadcast 'displayController.focusRange', index

	# reflect event from regionListItem to canvasWrapper
	$scope.$on 'regionListItem.focusRegion', (e, stamp) ->
		$scope.$broadcast 'displayController.focusRegion', stamp

	$scope.$on 'spectrumViewer.cursorPositionChanged', (e, index) ->
		renderer.updateDirectChannel index
		if settings.displayMode is C.DISPLAY_MODE.DIRECT
			renderer.update()

	return
