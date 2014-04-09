# directive for a list item in the ranges list of the menu in the display route
angular.module('quimbi').directive 'markerMenu', (markers, renderer, settings) ->

	restrict: 'A'

	templateUrl: './templates/markerMenu.html'

	scope: yes

	controller: ($scope) ->
		$scope.data =
			markers: null
			inDistancesMode: yes

		$scope.newMarker = ->
			markers.add()
			renderer.update()

		$scope.removeMarker = (index) ->
			markers.remove index
			renderer.update()

		$scope.editMarker = (index) ->
			markers.activate index
			markers.getList()[index].unset()
			renderer.update()

		$scope.showAdd = ->
			markers.getActiveIndex() is -1 and markers.getList().length < markers.getMaxNumber()

		$scope.$watch (-> settings.displayMode), (displayMode) ->
			$scope.data.markers = markers.getList()
			if displayMode is 'distances'
				$scope.data.inDistancesMode = yes
			else
				$scope.data.inDistancesMode = no
		
		return
