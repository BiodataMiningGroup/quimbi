# controller for the selection route
angular.module('quimbi').controller 'selectionCtrl', ($scope, state, selection) ->
	$scope.data = backRoute: "#/#{state.current()}"
	$scope.intensities = selection.intensities

	$scope.histogram =
		data: selection.intensities.map (element) -> element.length
		lowerBound: 0
		upperBound: 255

	$scope.histogram.maximum = $scope.histogram.data.reduce (previous, current) ->
			if previous < current then current else previous

	$scope.fingerprint = selection.fingerprint
	return