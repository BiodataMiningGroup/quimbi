# directive for a list item in the ranges list of the menu in the display route
angular.module('quimbi').directive 'markerMenu', (markers, regions, renderer) ->

	restrict: 'A'

	templateUrl: './templates/markerMenu.html'

	scope: yes

	controller: ($scope) ->
		$scope.data = markers: null

		$scope.disableAdd = -> markers.hasActive() or regions.isActive()

		$scope.newMarker = -> unless $scope.disableAdd()
			markers.add()
			renderer.update()

		$scope.removeMarker = (index) ->
			markers.remove index
			renderer.update()

		$scope.editMarker = (index) ->
			markers.activate index
			markers.getList()[index].unset()
			renderer.update()

		$scope.showAdd = -> markers.getList().length < markers.getMaxNumber()

		$scope.$watch (-> markers.getList()), (markersList) ->
			$scope.data.markers = markersList
		
		return
