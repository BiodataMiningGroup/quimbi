# directive to show a large dataset as spectrogram
angular.module('quimbi').directive 'spectrumViewer', ($window) ->
	
	restrict: 'A'

	templateUrl: './templates/spectrumViewer.html'

	replace: yes

	scope: 
		spectrum: '=spectrumViewer'
		# data, labels, maximum, minimum
		ranges: '=spectrumRanges'

	# link: (scope, element) ->

	# 	# zoom =
	# 	# 	step: 0.02
	# 	# 	min: scope.props.width / scope.data.length
	# 	# 	max: 1

	# 	# if zoom.min >= zoom.max then return
	# 	# element.on 'wheel', (e) ->
	# 	# 	delta = if e.deltaY < 0 then 1 else -1
	# 	# 	tmp = scope.props.zoom + delta * zoom.step
	# 	# 	tmp = Math.max zoom.min, tmp
	# 	# 	tmp = Math.min zoom.max, tmp
	# 	# 	scope.props.zoom = tmp
	# 	# 	scrollWidth = Math.round scope.data.length * tmp
	# 	# 	element.prop 'scrollLeft', 
	# 	# 	scope.$apply -> scope.scrollWidth = "#{scrollWidth}px"
	# 	return

	controller: ($scope, $element) ->
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
			zoom: 1
			# width of the content of the element
			scrollWidth: 0

		# the values of all spectral bars to display (not the whole dataset!)
		$scope.bars = []

		# style of the inner container, that adjusts it's left attribute to
		# be always displayed regardless the scroll position
		$scope.innerStyle = left: "0px"

		# style of the div that makes the spectrum viewer scrollable
		$scope.scrollStyle = width: "0px"

		# scope data container
		$scope.data = 
			current: 0
			label: ''
			value: ''
			length: 0
			# the index of the leftmost displayed bar in the complete dataset
			left: 0

		# all user made range selections
		$scope.ranges = []

		# currently active range (index of ranges array)
		activeRange = -1

		drawBars = (left) ->
			bar = $scope.props.width
			$scope.bars.length = bar
			$scope.bars[bar] = $scope.spectrum.data[left + bar] while bar--
			# valuesPerBar = Math.round 1 / $scope.props.zoom
			# leftOffset = Math.floor left / valuesPerBar
			# while bar--
			# 	offset = leftOffset + bar * valuesPerBar
			# 	value = valuesPerBar
			# 	$scope.bars[bar] = 0
			# 	$scope.bars[bar] += $scope.spectrum.data[offset + value] while value--
			# 	$scope.bars[bar] /= valuesPerBar

		updateProps = ->
			rect = $element[0].getBoundingClientRect()
			$scope.props.left = rect.left
			$scope.props.top = rect.top
			$scope.props.width = Math.min $element.prop('clientWidth'), $scope.data.length
			$scope.props.height = $element.prop 'clientHeight'
			$scope.props.scrollWidth = $scope.data.length

		$scope.finishRange = -> activeRange = -1

		$scope.mousemove = (e) ->
			index = e.pageX - $scope.props.left
			unless index < $scope.props.width then return
			$scope.data.current = index
			if activeRange < 0 then return
			range = $scope.ranges[activeRange]
			range.offset = $scope.data.left + index - range.start

		$scope.addRange = (e) ->
			unless activeRange < 0 then return
			activeRange = $scope.ranges.length
			$scope.ranges.push
				start: $scope.data.left + e.pageX - $scope.props.left
				offset: 1

		$scope.removeRange = (index) -> $scope.ranges.splice index, 1


		# element.on 'scroll', -> scope.$apply ->
		# 	scope.props.left = element.prop 'scrollLeft' / scope.props.scrollWidth
		$element.on 'scroll', -> $scope.$apply -> $scope.data.left = $element.prop 'scrollLeft'

		$window.addEventListener 'resize', -> $scope.$apply ->
			updateProps()
			drawBars $scope.data.left

		$scope.$watchCollection 'spectrum.data', ->
			$scope.data.length = $scope.spectrum.data.length 
			updateProps()
			drawBars $scope.data.left

		$scope.$watch 'props.scrollWidth', (width) -> $scope.scrollStyle.width = "#{width}px"

		$scope.$watch 'data.left', (left) ->
			$scope.innerStyle.left = "#{left}px"
			drawBars left

		$scope.$watch 'data.current', (current) ->
			index = current + $scope.data.left
			if index >= $scope.data.length then return
			$scope.data.label = "#{$scope.spectrum.labels[index]}"
			$scope.data.value = "#{$scope.spectrum.data[index]}"

		return
		