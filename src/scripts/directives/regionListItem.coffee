# directive for a list item in the regions list of the menu in the display route
angular.module('quimbi').directive 'regionListItem', (input, settings, regions) ->

	restrict: 'A'

	templateUrl: './templates/regionListItem.html'

	scope:
		region: '=regionListItem'
		index: '='

	replace: yes

	controller: ($scope) ->
		$scope.data =
			editing: no

		# toggles the editing mode for this list item
		$scope.edit = (e) ->
			e.stopPropagation()
			if $scope.data.editing
				$scope.region.editToolbar().save()
				$scope.region.editToolbar().disable()
			else
				$scope.region.editToolbar().enable()
			$scope.data.editing = not $scope.data.editing

		$scope.removeRegion = (e) ->
			e.stopPropagation()
			regions.remove $scope.region.getStamp()

		# toggles the active state of this item
		$scope.toggleRegion = (e) ->
			e.stopPropagation()
			if $scope.region.isActive()
				$scope.region.setInactive()
			else
				$scope.region.setActive()

		$scope.focusRegion = (e) -> if not $scope.data.editing and $scope.region.isActive()
			e.stopPropagation()
			$scope.$emit 'regionListItem.focusRegion', $scope.region.getStamp()

		$scope.class = ->
			active: $scope.region.isActive()
			editing: $scope.data.editing
		
		return
