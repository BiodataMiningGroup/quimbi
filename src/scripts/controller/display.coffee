# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, input, settings, renderer, markers) ->
	$scope.settings = settings

	$scope.selectionData = markers.selectionData

	$scope.spectrum =
		layers: []
		labels: input.channelNames
		maximum: 255
		minimum: 0
		length: input.channels

	$scope.spectrumRanges = []

	# updates the spectrograms of the different selections to display in the
	# spectrum viewer
	updateSelections = (selections) ->
		layers = $scope.spectrum.layers
		layers.length = selections.length
		for selection, index in selections
			if not layers[index]? then layers[index] = {}
			layers[index].color = selection.color
			layers[index].data = selection.data.spectrogram


	$scope.$watch "selectionData", updateSelections, yes

	$scope.$watch 'spectrumRanges', renderer.updateChannelMask, yes

	# $scope.$watch 'settings.displayMode', ranges.update

	# reflect event from rangeListItem to spectrumViewer
	$scope.$on 'rangeListItem.focusRange', (e, index) ->
		$scope.$broadcast 'spectrumViewer.focusRange', index

	return
