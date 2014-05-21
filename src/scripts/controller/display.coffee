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


	$scope.$watch markers.getSelectionData, updateSelections, yes

	$scope.$watch 'spectrumRanges', renderer.updateChannelMask, yes

	$scope.$watch 'settings.displayMode', renderer.updateChannelMask
	$scope.$watch 'settings.displayMode', renderer.update

	$scope.$watch 'settings.displayMode', (displayMode) ->
		unless markers.getList()[0]?.isSet()
			# activate first marker when switching display modes if it isn't already set
			markers.switchOn 0
		else
			# else prevent the active state of the first marker to leak to the other
			# display mode
			markers.deactivate()

	# watch for change between single and multi selection markers
	# if there ist a change, update the current color maps accordingly
	$scope.$watchCollection (->markers.getList()), (markerList) ->
		if markerList.length is 1
			switch markerList[0].getType()
				when 'multi' then settings.activeColorMaps = settings.colorMaps
				else settings.activeColorMaps = singleSelectionColorMaps
			renderer.updateColorMaps()

	# reflect event from rangeListItem to spectrumViewer
	$scope.$on 'rangeListItem.focusRange', (e, index) ->
		$scope.$broadcast 'spectrumViewer.focusRange', index

	return
