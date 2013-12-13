# directive for a tool button displayed in the display route. registers a new
# tool in the toolset (if not already present) and manages the "draw" and
# "clear" events
angular.module('quimbi').directive 'toolButton', (toolset) ->
	
	restrict: 'A'

	templateUrl: './templates/toolButton.html'

	scope: yes

	replace: yes

	link: (scope, element, attrs) ->
		# add this tool to the toolset
		scope.tool = toolset.add attrs['toolButton']
		return

	controller: ($scope, $element, $attrs) ->
		$scope.draw = -> toolset.draw $scope.tool.id
		$scope.clear = ->	toolset.clear $scope.tool.id
		return