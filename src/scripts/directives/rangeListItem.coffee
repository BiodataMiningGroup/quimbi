# directive for a list item in the ranges list of the menu in the display route
angular.module('quimbi').directive 'rangeListItem', (input, settings, colorGroups, ranges, C) ->

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

		$scope.inMeanMode = -> settings.displayMode is C.DISPLAY_MODE.MEAN

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
		$scope.toggleRange = (e) ->
			e.stopPropagation()
			if $scope.range.isActive()
				$scope.range.setInactive()
			else
				$scope.range.setActive()

		$scope.focusRange = (e) -> unless $scope.data.editing
			e.stopPropagation()
			$scope.$emit 'rangeListItem.focusRange', $scope.index

		$scope.class = ->
			active: $scope.range.isActive()
			editing: $scope.data.editing

		$scope.style = -> if $scope.inMeanMode()
			'border-left-color': $scope.range.getColor()

		# NOTE: this would have been easier if the decrease/increase buttons
		# could use ng-disabled but this breaks the tooltip behaviour
		$scope.canIncreaseStart = ->
			$scope.range.start < input.channels - $scope.range.offset

		$scope.canDecreaseStart = ->
			$scope.range.start > 0

		$scope.canIncreaseOffset = ->
			$scope.range.offset < input.channels - $scope.range.start

		$scope.canDecreaseOffset = ->
			$scope.range.offset > 1

		$scope.hasOffset = -> $scope.data.startLabel isnt $scope.data.endLabel

		$scope.changeStart = (offset) ->
			if (offset < 0 and $scope.canDecreaseStart()) or (offset > 0 and $scope.canIncreaseStart())
				$scope.range.start += offset

		$scope.changeOffset = (offset) ->
			if (offset < 0 and $scope.canDecreaseOffset()) or (offset > 0 and $scope.canIncreaseOffset())
				$scope.range.offset += offset

		updateEndLabel = (offset) ->
			# offset - 1 so start == end when offset == 1
			$scope.data.endLabel = input.channelNames[$scope.range.start + offset - 1]

		updateStartLabel = (start) ->
			$scope.data.startLabel = input.channelNames[start]
			updateEndLabel $scope.range.offset

		$scope.$watch 'range.start', updateStartLabel

		$scope.$watch 'range.offset', updateEndLabel
		
		return
