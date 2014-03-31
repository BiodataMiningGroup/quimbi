# directive for a list item in the ranges list of the menu in the display route
angular.module('quimbi').directive 'rangeListItem', (ranges, input, settings) ->

	restrict: 'A'

	templateUrl: './templates/rangeListItem.html'

	scope:
		range: '=rangeListItem'
		index: '='

	replace: yes

	controller: ($scope) ->
		$scope.data =
			label: ''
			choosingGroup: no

		$scope.inMeanMode = -> settings.displayMode is 'mean'

		$scope.chooseGroup = (e) ->
			e.stopPropagation()
			$scope.data.choosingGroup = not $scope.data.choosingGroup

		$scope.removeRange = (e) ->
			e.stopPropagation()
			ranges.splice $scope.index, 1

		$scope.toggleRange = ->
			$scope.range.active = not $scope.range.active
			$scope.$emit 'rangeListItem.focusRange', $scope.index

		$scope.class = ->
			active: $scope.range.active

		$scope.style = -> if $scope.inMeanMode()
			'border-left-color': $scope.range.group

		updateLabel = ->
			$scope.data.label = input.channelNames[$scope.range.start]
			if $scope.range.offset > 1
				$scope.data.label += ' - ' +
					input.channelNames[$scope.range.start + $scope.range.offset]

		$scope.$watch 'range.start', updateLabel
		$scope.$watch 'range.offset', updateLabel

		$scope.$watch 'range.group', (group) ->
			$scope.data.choosingGroup = no
		
		return
