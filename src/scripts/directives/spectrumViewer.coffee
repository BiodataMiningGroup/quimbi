# directive to show a large dataset as spectrogram
angular.module('quimbi').directive 'spectrumViewer', ->
	
	restrict: 'A'

	templateUrl: './templates/spectrumViewer.html'

	replace: yes

	scope: 
		spectrum: '=spectrumViewer'
		# data, labels, maximum, minimum

	link: (scope, element) ->
		scope.scrollStyle = width: "#{scope.spectrum.data.length}px"

		element.on 'scroll', -> scope.$apply -> scope.updateBars element.prop 'scrollLeft'
		scope.props.width = element.prop 'clientWidth'
		scope.props.height = element.prop 'clientHeight'

		# init bars
		scope.updateBars element.prop 'scrollLeft'
		return

	controller: ($scope) ->
		$scope.props =	width: 0
		$scope.bars = []
		$scope.innerStyle = left: "0px"

		$scope.updateBars = (left) ->
			$scope.innerStyle.left = "#{left}px"
			bar = $scope.props.width
			$scope.bars[bar] = $scope.spectrum.data[bar + left] while bar--

		return
		