# directive for a list item in the ranges list of the menu in the display route
angular.module('quimbi').directive 'markerMenu', (marker, renderer) ->

	restrict: 'A'

	templateUrl: './templates/markerMenu.html'

	scope: yes

	controller: ($scope) ->
		$scope.data =
			marker: marker.list

		$scope.newMarker = ->
			marker.add()
			renderer.update()

		$scope.removeMarker = (index) ->
			marker.remove index
			renderer.update()

		$scope.editMarker = (index) ->
			marker.activate index
			renderer.update()

		$scope.showAdd = -> marker.list.length < marker.maxNumber
		
		return
