# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, input, settings, renderer, markers, ranges) ->

	renderer.updateColorMaps()

	# one active marker by default
	markers.add() if markers.getList().length is 0

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
		unless markers.getList()[0].isSet()
			# activate first marker when switching display modes if it isn't already set
			markers.activate 0
		else
			# else prevent the active state of the first marker to leak to the other
			# display mode
			markers.activate -1

	# reflect event from rangeListItem to spectrumViewer
	$scope.$on 'rangeListItem.focusRange', (e, index) ->
		$scope.$broadcast 'spectrumViewer.focusRange', index

	return
