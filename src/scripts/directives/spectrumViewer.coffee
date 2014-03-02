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

		# update viewer properties
		updateProps = ->
			scope.props.scrollWidth = scope.data.length
			scope.props.width =
				Math.min element.prop('clientWidth'), scope.data.length
			scope.props.height = element.prop('clientHeight') - 25 #25px x-axis height
			canvas.width = scope.props.width
			canvas.height = scope.props.height

		# draw the spectrum
		draw = (left) ->
			height = canvas.height
			width = canvas.width
			# clear canvas
			ctx.clearRect 0, 0, width, height
			ctx.beginPath()
			# coefficient to calculate the y position
			yPosition = height / scope.spectrum.maximum
			# start from bottom right
			ctx.moveTo width, height
			position = scope.props.width
			data = scope.spectrum.data
			while position--
				ctx.lineTo position, height - yPosition * data[left + position]
			ctx.strokeStyle = '#ffffff'
			ctx.stroke()

		element.on 'scroll', -> scope.$apply ->
			scope.data.left = element.prop 'scrollLeft'

		# update element and viewer properties if the window size changes and redraw
		$window.addEventListener 'resize', -> scope.$apply ->
			rect = element[0].getBoundingClientRect()
			scope.props.left = rect.left
			scope.props.top = rect.top
			updateProps()
			draw scope.data.left

		# update and redraw if the input data changes
		scope.$watchCollection 'spectrum.data', ->
			scope.data.length = scope.spectrum.data.length 
			updateProps()
			draw scope.data.left

		# adjust size of the scroll container when scrollWidth changes
		scope.$watch 'props.scrollWidth', (width) ->
			scope.scrollStyle.width = "#{width}px"

		# redraw and move inner container when the viewport changes
		scope.$watch 'data.left', (left) ->
			# update scrollLeft in case of manual scrolling
			element.prop 'scrollLeft', left
			scope.innerStyle['transform'] =
				scope.innerStyle['-webkit-transform'] =
					"translate(#{left}px,0px)"
			draw left

		# update the information of the currently hovered position
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
		$scope.innerStyle =
			transform: "translate(0px,0px)"
			'-webkit-transform': "translate(0px,0px)"

		# style of the bar that marks the mouse position
		$scope.indicatorStyle = left: "0px"

		# style of the div that makes the spectrum viewer scrollable
		$scope.scrollStyle = width: "0px"

		# scope data container
		$scope.data =
			# index of the currently hovered position
			current: 0
			# x-axiy value of the currently hovered position
			label: '-'
			# y-axis value of the currently hovered position
			value: '-'
			# number of channels of the dataset
			length: 0
			# the index of the leftmost displayed bar in the complete dataset
			left: 0
			# start point for manually scrolling by 'grabbing' the viewer
			scrollStart: -1
			# value of scrollLeft when manual scrolling has started
			scrollStartLeft: 0
			# currently active range (index of ranges array)
			activeRange: -1

		# all user made range selections
		$scope.ranges = []

		$scope.scrollStart = (e) -> if e.button is 0 and not e.shiftKey
			posX = e.pageX - $scope.props.left
			$scope.data.scrollStart = posX
			$scope.data.scrollStartLeft = $scope.data.left

		$scope.scroll = (e) -> unless $scope.data.scrollStart < 0
			posX = e.pageX - $scope.props.left
			if posX > $scope.props.width then return
			
			left = $scope.data.scrollStartLeft + $scope.data.scrollStart - posX
			left = Math.max left, 0
			left = Math.min left, $scope.props.scrollWidth - $scope.props.width
			$scope.data.left = left

		$scope.scrollEnd = -> $scope.data.scrollStart = -1

		$scope.mousemove = (e) ->
			posX = e.pageX - $scope.props.left
			if posX > $scope.props.width then return

			$scope.data.current = posX

			# update active range
			unless $scope.data.activeRange < 0
				range = $scope.ranges[$scope.data.activeRange]
				offset = $scope.data.left + posX - range.start
				# minimal offset is 1 (one chanel selected)
				range.offset = Math.max offset, 1

		$scope.mouseup = -> if $scope.data.activeRange >= 0
			$scope.data.activeRange = -1
			$scope.$emit 'spectrumViewer.rangesUpdated'

		$scope.mousedown = (e) -> if e.button is 0
			posX = e.pageX - $scope.props.left
			if $scope.data.activeRange < 0 and e.shiftKey
				$scope.data.activeRange = $scope.ranges.length
				if posX < $scope.props.width then $scope.ranges.push
					start: $scope.data.left + posX
					offset: 1

		$scope.removeRange = (index) ->
			$scope.ranges.splice index, 1
			$scope.$emit 'spectrumViewer.rangesUpdated'

		return
		