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

	$scope.channelNames = input.channelNames

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

	updateRanges = (ranges) ->
		# number of channels padded to be represented as vec4's
		channel = input.files.length * 4
		hasActiveRange = no
		for range in ranges when range.active
			hasActiveRange = yes
			break
		if hasActiveRange
			channelMask[channel] = 0 while channel--
			for range in ranges when range.active
				offset = range.offset
				channelMask[range.start + offset] = 255 while offset--
		else
			channelMask[channel] = 255 while channel--	
		shader.updateChannelMask channelMask
		# TODO for multiple passive tools make function in toolset that runs this
		# once for all passive tools
		glmvilib.render.apply glmvilib, shader.getActive()

	$scope.$watch 'spectrumRanges', updateRanges, yes

	$scope.removeRange = (index) ->
		$scope.spectrumRanges.splice index, 1
	
	return