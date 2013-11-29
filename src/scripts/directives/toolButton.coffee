angular.module('quimbi').directive 'toolButton', (toolset) ->
	
	restrict: 'A'

	templateUrl: './templates/toolButton.html'

	scope: yes

	replace: yes

	link: (scope, element, attrs) ->
		scope.tool = toolset.add attrs['toolButton']
		return

	controller: ($scope, $element, $attrs) ->
		$scope.draw = -> toolset.draw $scope.tool.id
		$scope.clear = ->	toolset.clear $scope.tool.id
		return