# directive to make a histogram out of a data series
angular.module('quimbi').directive 'histogram', ->
	
	restrict: 'A'

	templateUrl: './templates/histogram.html'

	replace: yes

	scope: 
		data: '=histogram'
		maximum: '=maximum'
		lowerBound: '=lowerBound'
		upperBound: '=upperBound'

	link: (scope) ->
		scope.values = scope.data

	controller: ($scope) ->
		updateValues = (value) ->
			$scope.values = $scope.data.slice $scope.lowerBound, $scope.upperBound
		$scope.$watch 'upperBound', updateValues
		$scope.$watch 'lowerBound', updateValues