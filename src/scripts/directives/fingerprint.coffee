# directive to append a canvas to the dom
angular.module('quimbi').directive 'fingerprint', ->
	
	restrict: 'A'

	scope: 
		canvas: '=fingerprint'

	link: (scope, element) ->
		element.append scope.canvas