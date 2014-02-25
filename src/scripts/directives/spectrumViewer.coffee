# directive to show a large dataset as spectrogram
angular.module('quimbi').directive 'spectrumViewer', ($window) ->
	
	restrict: 'A'

	templateUrl: './templates/spectrumViewer.html'

	replace: yes

	scope: 
		spectrum: '=spectrumViewer'
		# data, labels, maximum, minimum
		ranges: '=spectrumRanges'

	link: (scope, element) ->
		canvas = element.find('canvas')[0]
		ctx = canvas.getContext '2d'

		updateProps = ->
			scope.props.width = Math.min element.prop('clientWidth'), scope.data.length
			scope.props.height = element.prop 'clientHeight'
			canvas.width = scope.props.width
			canvas.height = scope.props.height
			scope.props.scrollWidth = scope.data.length

		drawBars = (left) ->
			bar = scope.props.width
			# clear canvas
			canvas.width = canvas.width
			ctx.beginPath()
			# coefficient to calculate the y position
			yPosition = canvas.height / scope.spectrum.maximum
			# start from bottom right
			ctx.moveTo canvas.width, canvas.height
			ctx.lineTo bar, canvas.height - yPosition * scope.spectrum.data[left + bar] while bar--
			ctx.strokeStyle = '#ffffff'
			ctx.lineWidth = 1
			ctx.stroke()

		element.on 'scroll', -> scope.$apply -> scope.data.left = element.prop 'scrollLeft'

		$window.addEventListener 'resize', -> scope.$apply ->
			rect = element[0].getBoundingClientRect()
			scope.props.left = rect.left
			scope.props.top = rect.top
			updateProps()
			drawBars scope.data.left

		scope.$watchCollection 'spectrum.data', ->
			scope.data.length = scope.spectrum.data.length 
			updateProps()
			drawBars scope.data.left

		scope.$watch 'props.scrollWidth', (width) -> scope.scrollStyle.width = "#{width}px"

		scope.$watch 'data.left', (left) ->
			scope.innerStyle.left = "#{left}px"
			drawBars left

		scope.$watch 'data.current', (current) ->
			scope.indicatorStyle.left = "#{current}px"
			index = current + scope.data.left
			if index >= scope.data.length then return
			scope.data.label = "#{scope.spectrum.labels[index]}"
			scope.data.value = "#{Math.round scope.spectrum.data[index] / scope.spectrum.maximum * 100}"


	controller: ($scope) ->
		# properties of the spectrum viewer element
		$scope.props =
			# width of the element and number of displayed bars
			width: 0
			# height of the element
			height: 0
			# left coordinate of the element
			left: 0
			# top coordinate of the element
			top: 0
			# width of the content of the element
			scrollWidth: 0

		# style of the inner container, that adjusts it's left attribute to
		# be always displayed regardless the scroll position
		$scope.innerStyle = left: "0px"

		# style of the bar that marks the mouse position
		$scope.indicatorStyle = left: "0px"

		# style of the div that makes the spectrum viewer scrollable
		$scope.scrollStyle = width: "0px"

		# scope data container
		$scope.data = 
			current: 0
			label: '-'
			value: '-'
			length: 0
			# the index of the leftmost displayed bar in the complete dataset
			left: 0

		# all user made range selections
		$scope.ranges = []

		# currently active range (index of ranges array)
		activeRange = -1

		$scope.mousemove = (e) ->
			index = e.pageX - $scope.props.left
			unless index < $scope.props.width then return
			$scope.data.current = index
			if activeRange < 0 then return
			range = $scope.ranges[activeRange]
			range.offset = $scope.data.left + index - range.start

		$scope.finishRange = -> activeRange = -1

		$scope.addRange = (e) ->
			unless e.button is 0 then return
			unless activeRange < 0 then return
			activeRange = $scope.ranges.length
			$scope.ranges.push
				start: $scope.data.left + e.pageX - $scope.props.left
				offset: 1

		$scope.removeRange = (index) -> $scope.ranges.splice index, 1

		return
		