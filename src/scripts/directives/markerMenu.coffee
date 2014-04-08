# directive for a list item in the ranges list of the menu in the display route
angular.module('quimbi').directive 'markerMenu', (markers, renderer) ->

	restrict: 'A'

	templateUrl: './templates/markerMenu.html'

	scope: yes

	controller: ($scope) ->
		$scope.data =
			markers: markers.list

		$scope.newMarker = ->
			markers.add()
			renderer.update()

		$scope.removeMarker = (index) ->
			markers.remove index
			renderer.update()

		$scope.editMarker = (index) ->
			markers.activate index
			markers.list[index].unset()
			renderer.update()

		$scope.showAdd = ->
			markers.getActiveIndex() is -1 and markers.list.length < markers.maxNumber
		
		return
