# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, input, selection, shader, toolset) ->
	channelMask = new Uint8Array selection.textureDimension * selection.textureDimension * 4

	$scope.selections = toolset.selections

	$scope.spectrum =
		layers: {}
		labels: input.channelNames
		maximum: 255
		minimum: 0
		length: 0

	$scope.spectrumRanges = []

	updateSelections = (selections) ->
		index = 0
		layers = $scope.spectrum.layers
		# fill layers to have as many entries as there are selections
		for id of selections when not layers.hasOwnProperty id
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

	updateRanges = ->
		# number of channels padded to be represented as vec4's
		channel = input.files.length * 4
		if $scope.spectrumRanges.length is 0
			channelMask[channel] = 255 while channel--	
		else
			channelMask[channel] = 0 while channel--
			for range in $scope.spectrumRanges
				offset = range.offset
				channelMask[range.start + offset] = 255 while offset--
		shader.updateChannelMask channelMask
		# TODO for multiple passive tools make function in toolset that runs this
		# once for all passive tools
		glmvilib.render.apply glmvilib, shader.getActive()

	$scope.$on 'spectrumViewer.rangesUpdated', updateRanges
	updateRanges()
	
	return