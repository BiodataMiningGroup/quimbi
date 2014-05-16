# directive for a list item in the ranges list of the menu in the display route
angular.module('quimbi').directive 'markerMenu', (markers, regions, renderer) ->

	restrict: 'A'

	templateUrl: './templates/markerMenu.html'

	scope: yes

	controller: ($scope) ->
		$scope.data = markers: null

		$scope.switchOffMarker = (index) ->
			markers.switchOff index
			renderer.update()

		$scope.switchOnMarker = (index) ->
			markers.switchOn index
			renderer.update()

		$scope.onlyMarker = ->
			count = 0
			count++ for marker in $scope.data.markers when marker.isOn()
			count is 1

		$scope.$watch (-> markers.getListAll()), (markersList) ->
			$scope.data.markers = markersList
		
		return
