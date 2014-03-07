# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, input, selection, shader) ->
	channelMask = new Uint8Array selection.textureDimension * selection.textureDimension * 4

	$scope.spectrum =
		data: [selection.data.byName]
		labels: input.channelNames
		maximum: selection.data.maxIntensity
		minimum: selection.data.minIntensity
		length: 0

	$scope.spectrumRanges = []

	$scope.$on "canvasWrapper.updateSelection", ->
		# TODO: each tool has its own selection info so multiple spectrograms
		# can be displayed simultaneously in the spectrum viewer
		$scope.spectrum.data[0].length = selection.data.byName.length
		for i in [0...selection.data.byName.length]
			$scope.spectrum.data[0][i] = selection.data.byName[i]		
		$scope.spectrum.maximum = selection.data.maxIntensity
		$scope.spectrum.minimum = selection.data.minIntensity
		$scope.spectrum.length = input.channels

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
		glmvilib.render.apply glmvilib, shader.getActive()

	$scope.$on 'spectrumViewer.rangesUpdated', updateRanges
	updateRanges()
	
	return