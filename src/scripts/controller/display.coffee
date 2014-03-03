# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, input, selection, shader) ->
	channelMask = new Uint8Array selection.textureDimension * selection.textureDimension * 4
	console.log selection.textureDimension

	$scope.spectrum =
		data: selection.data.byName
		labels: input.channelNames
		maximum: selection.data.maxIntensity
		minimum: selection.data.minIntensity

	$scope.spectrumRanges = []

	$scope.$on "canvasWrapper.updateSelection", ->
		$scope.spectrum.data = selection.data.byName
		$scope.spectrum.maximum = selection.data.maxIntensity
		$scope.spectrum.minimum = selection.data.minIntensity

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