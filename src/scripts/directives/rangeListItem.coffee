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
			startLabel: ''
			endLabel: ''
			editing: no
			colorGroups: colorGroups.getAll()

		$scope.inMeanMode = -> settings.displayMode is 'mean'

		# toggles the editing mode for this list item
		$scope.edit = (e) ->
			e.stopPropagation()
			$scope.data.editing = not $scope.data.editing

		# sets the chosen color group for this item
		$scope.setColorGroup = (e, group) ->
			e.stopPropagation()
			$scope.range.setGroup group

		$scope.removeRange = (e) ->
			e.stopPropagation()
			ranges.remove $scope.index

		# toggles the active state of this item
		$scope.toggleRange = -> unless $scope.data.editing
			if $scope.range.isActive()
				$scope.range.setInactive()
			else
				$scope.range.setActive()
			$scope.$emit 'rangeListItem.focusRange', $scope.index

		$scope.class = -> active: $scope.range.isActive()

		$scope.style = -> if $scope.inMeanMode()
			'border-left-color': $scope.range.getColor()

		# returns the maximal possible range.start value to choose
		$scope.maxStart = ->	input.channels - $scope.range.offset

		# returns the maximal possible range.offset value to choose
		$scope.maxOffset = -> input.channels - $scope.range.start

		updateStartLabel = (start) ->
			$scope.data.startLabel = input.channelNames[start]

		$scope.$watch 'range.start', updateStartLabel

		updateEndLabel = (offset) ->
			$scope.data.endLabel = if offset <= 1 then '' else
				input.channelNames[$scope.range.start + offset]

		$scope.$watch 'range.offset', updateEndLabel
		
		return
