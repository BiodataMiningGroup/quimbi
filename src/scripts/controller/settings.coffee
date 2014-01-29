# controller for the settings route
angular.module('quimbi').controller 'settingsCtrl', ($scope, settings, input) ->
	$scope.settings = settings
	# additional information that can't be set directly
	$scope.info =
		normMethod: ''
		norm: 0
		hasOverlay: input.overlayImage isnt ''

	updateDistMethod = (newDistMethod) ->
		switch newDistMethod
			when 'angle'
				$scope.info.normMethod = input.angleDistNormMethod
				$scope.info.norm = input.maxAngleDist
			when 'eucl'
				$scope.info.normMethod = input.euclDistNormMethod
				$scope.info.norm = input.maxEuclDist

	$scope.$watch 'settings.distMethod', updateDistMethod
	return