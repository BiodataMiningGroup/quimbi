# controller for the about route
angular.module('quimbi').controller 'aboutCtrl', ($scope, state) ->
	$scope.data = backRoute: "#/#{state.current()}"
	return