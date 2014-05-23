# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, input, settings, renderer, markers, ranges) ->

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

	# updates the spectrograms of the different selections to display in the
	# spectrum viewer
	updateSelections = (selections) ->
		layers = $scope.spectrum.layers
		layers.length = selections.length
		for selection, index in selections
			if not layers[index]? then layers[index] = {}
			layers[index].color = selection.color
			layers[index].data = selection.data.spectrogram

	# returns the list of colorGroupObjects that determines the colorMaps
	# according to the current display mode
	getCurrentList = -> switch settings.displayMode
		when 'mean' then ranges.getActive()
		else markers.getList()

	$scope.$watch markers.getSelectionData, updateSelections, yes

	$scope.$watch 'spectrumRanges', renderer.updateChannelMask, yes

	updateActiveColorMaps = (list) ->
		for colorGroupObject in list
			settings.activeColorMaps[colorGroupObject.getIndex()] =
				colorGroupObject.getColorMapName()
		renderer.updateColorMaps()
		renderer.update()

	$scope.$watch getCurrentList, updateActiveColorMaps, yes

	$scope.$watch 'settings.displayMode', (displayMode) ->
		renderer.updateChannelMask()
		renderer.update()

		unless markers.getList()[0]?.isSet()
			# activate first marker when switching display modes if it isn't already set
			markers.switchOn 0
		else
			# else prevent the active state of the first marker to leak to the other
			# display mode
			markers.deactivate()

	# reflect event from rangeListItem to spectrumViewer
	$scope.$on 'rangeListItem.focusRange', (e, index) ->
		$scope.$broadcast 'spectrumViewer.focusRange', index

	return
