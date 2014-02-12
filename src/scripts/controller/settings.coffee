# controller for the settings route
angular.module('quimbi').controller 'settingsCtrl', ($scope, settings, input, colorMapParser) ->
	$scope.settings = settings
	# additional information that can't be set directly
	$scope.info =
		normMethod: ''
		norm: 0
		hasOverlay: input.overlayImage isnt ''
	$scope.data =
		colorMapFile: null

	updateDistMethod = (newDistMethod) ->
		switch newDistMethod
			when 'angle'
				$scope.info.normMethod = input.angleDistNormMethod
				$scope.info.norm = input.maxAngleDist
			when 'eucl'
				$scope.info.normMethod = input.euclDistNormMethod
				$scope.info.norm = input.maxEuclDist

	setNewColorMap = (colorMapFile) ->
		if colorMapFile
			try
				settings.colorMap = colorMapParser.parse colorMapFile
			catch e
				$scope.$emit 'message::error', e.message

	$scope.$watch 'settings.distMethod', updateDistMethod
	$scope.$watch 'data.colorMapFile', setNewColorMap
	return