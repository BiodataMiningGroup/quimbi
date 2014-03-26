# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, input, selection, toolset, ranges) ->
	channelMask = new Uint8Array selection.textureDimension * selection.textureDimension * 4

	$scope.selections = toolset.selections

	$scope.spectrum =
		layers: {}
		labels: input.channelNames
		maximum: 255
		minimum: 0
		length: 0

	$scope.channelNames = input.channelNames

	$scope.spectrumRanges = ranges

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

	$scope.$watch "selections", updateSelections, yes	

	# updates the channelMask filter according to the selected ranges in the
	# spectrum viewer
	updateRanges = (newRanges) ->
		# number of channels padded to be represented as vec4's
		channel = input.files.length * 4
		hasActiveRange = no
		for range in newRanges when range.active
			hasActiveRange = yes
			break
		if hasActiveRange
			channelMask[channel] = 0 while channel--
			for range in newRanges when range.active
				offset = range.offset
				channelMask[range.start + offset] = 255 while offset--
		else
			channelMask[channel] = 255 while channel--
		toolset.updateChannelMask channelMask

	$scope.$watch 'spectrumRanges', updateRanges, yes

	$scope.removeRange = (index) -> $scope.spectrumRanges.splice index, 1

	$scope.toggleRange = (index, range) ->
		range.active = not range.active
		$scope.$broadcast 'spectrumViewer.focusRange', index
	
	return