# directive for a tool point displayed on the canvas in the display route.
# registers a new tool in the toolset (if not already present) and manages the
# "draw" event
angular.module('quimbi').directive 'toolPoint', (toolset, settings) ->
	
	restrict: 'A'

	templateUrl: './templates/toolPoint.html'

	scope: yes

	replace: yes

	link: (scope, element, attrs) ->
		scope.tool = toolset.add attrs['toolPoint']
		return

	controller: ($scope, $element, $attrs) ->
		$scope.draw = -> toolset.draw $scope.tool.id
		$scope.element = show: no

		updateShow = (newShow) -> if settings.showPoints then $scope.element.show = newShow
		$scope.$watch 'tool.passive', updateShow
		return