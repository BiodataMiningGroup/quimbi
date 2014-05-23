# directive for a list item in the ranges list of the menu in the display route
angular.module('quimbi').directive 'rangeListItem', (input, settings, colorGroups, ranges) ->

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
			colorGroups: colorGroups.getAll()

		$scope.inMeanMode = -> settings.displayMode is 'mean'

		$scope.chooseGroup = (e) ->
			e.stopPropagation()
			$scope.data.choosingGroup = not $scope.data.choosingGroup

		$scope.setColorGroup = (e, group) ->
			e.stopPropagation()
			$scope.data.choosingGroup = no
			$scope.range.setGroup group

		$scope.removeRange = (e) ->
			e.stopPropagation()
			ranges.remove $scope.index

		$scope.toggleRange = ->
			if $scope.range.isActive()
				$scope.range.setInactive()
			else
				$scope.range.setActive()
			$scope.$emit 'rangeListItem.focusRange', $scope.index

		$scope.class = ->
			active: $scope.range.isActive()

		$scope.style = -> if $scope.inMeanMode()
			'border-left-color': $scope.range.getColor()

		updateLabel = ->
			$scope.data.label = input.channelNames[$scope.range.start]
			if $scope.range.offset > 1
				$scope.data.label += ' - ' +
					input.channelNames[$scope.range.start + $scope.range.offset]

		$scope.$watch 'range.start', updateLabel
		$scope.$watch 'range.offset', updateLabel
		
		return
