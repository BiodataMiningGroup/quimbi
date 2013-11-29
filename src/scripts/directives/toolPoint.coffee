angular.module('quimbi').directive 'toolPoint', (toolset) ->
	
	restrict: 'A'

	templateUrl: './templates/toolPoint.html'

	scope: yes

	replace: yes

	link: (scope, element, attrs) ->
		scope.tool = toolset.add attrs['toolPoint']
		return

	controller: ($scope, $element, $attrs) ->
		
		return