# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, input, settings, marker) ->
	$scope.settings = settings

	# $scope.selections = marker.selectionData

	marker.add()
	marker.set x: 0.2, y: 0.4
	console.log marker.selectionData

	$scope.spectrum =
		layers: {}
		labels: input.channelNames
		maximum: 255
		minimum: 0
		length: 0

	# $scope.spectrumRanges = []

	# updates the spectrograms of the different selections to display in the
	# spectrum viewer
	updateSelections = (selections) ->
		index = 0
		layers = $scope.spectrum.layers
		# fill layers to have as many entries as there are selections
		for id of selections when not layers.hasOwnProperty id
			# id is the color but can be something else, too!
			layers[id] = data: [], color: id
		# remove old layers that should no longer be shown
		delete layers[id] for id of layers when not selections.hasOwnProperty id

		for id, data of selections
			byName = data.byName
			layers[id].data.length = byName.length
			layers[id].data[i] = byName[i] for i in [0...byName.length]
			index++
		$scope.spectrum.length = input.channels

	# $scope.$watch "selections", updateSelections, yes

	# $scope.$watch 'spectrumRanges', ranges.update, yes

	# $scope.$watch 'settings.displayMode', ranges.update

	# reflect event from rangeListItem to spectrumViewer
	$scope.$on 'rangeListItem.focusRange', (e, index) ->
		$scope.$broadcast 'spectrumViewer.focusRange', index

	return
