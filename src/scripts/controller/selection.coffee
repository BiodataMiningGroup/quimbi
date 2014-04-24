# controller for the selection route
angular.module('quimbi').controller 'selectionCtrl', ($scope, state, selection) ->
	$scope.data = backRoute: "#/#{state.current()}"
	$scope.intensities = selection.data.byValue

	$scope.histogram =
		data: selection.data.byValue.map (element) -> element.length

	$scope.histogram.maximum = $scope.histogram.data.reduce (previous, current) ->
		if previous < current then current else previous

	$scope.show =
		spectrum: yes
		histogram: no
		fingerprint: no
		values: no

	$scope.fingerprint = selection.fingerprint
	return
