# directive to make a histogram out of a data series
angular.module('quimbi').directive 'histogram', ->
	
	restrict: 'A'

	templateUrl: './templates/histogram.html'

	replace: yes

	scope: 
		data: '=histogram'
		maximum: '=maximum'

	link: (scope) ->
		scope.values = scope.data