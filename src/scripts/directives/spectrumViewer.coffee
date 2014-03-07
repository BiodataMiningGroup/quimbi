# directive to show a large dataset as spectrogram
angular.module('quimbi').directive 'spectrumViewer', ($window) ->
	
	restrict: 'A'

	templateUrl: './templates/spectrumViewer.html'

	replace: yes

	scope: 
		# data, labels, maximum, minimum
		spectrum: '=spectrumViewer'
		# array of {start: Number, offset: Number} objects
		ranges: '=spectrumRanges'

	link: (scope, element) ->
		canvas = element.find('canvas')[0]
		ctx = canvas.getContext '2d'

		# update viewer properties
		updateProps = ->
			canvas.width = scope.props.width = element.prop('clientWidth')
			canvas.height = scope.props.height = element.prop('clientHeight') - 25 #25px x-axis height

			if scope.data.length is 0 then return

			scope.zoom.min = scope.props.width / scope.data.length
			# checks if current zoom.factor is smaller than the new zoom.min
			scope.zoom.factor = scope.zoom.factor

			# minimal number is 1
			scope.labels.length = Math.ceil scope.props.width / scope.props.labelWidth

		# update the displayed x-axis labels
		updateLabels = (left) ->
			labels = scope.labels
			spectrumLabels = scope.spectrum.labels
			# index of leftmost visible point
			left = Math.round left / scope.zoom.factor
			# number of labels to display
			number = scope.labels.length
			# index offset of the datapoints that get a label
			offset = Math.round scope.props.width / (scope.zoom.factor * number)
			# pixel offset of the displayed labels
			scope.props.labelOffset = offset * scope.zoom.factor
			labels[number] = spectrumLabels[left + number * offset] while number--

		# draw the spectrum
		drawHeight = drawWidth = drawZoom = drawLeft = heightCoefficient = drawNumber = 0
		drawData = null
		drawColor = 'white'
		draw = (left) ->
			drawHeight = canvas.height
			drawWidth = canvas.width
			drawZoom = scope.zoom.factor
			drawLeft = Math.round left / drawZoom
			heightCoefficient = drawHeight / scope.spectrum.maximum
			# number of datapoints to display in the current viewport
			drawNumber = Math.round drawWidth / drawZoom
			drawData = scope.spectrum.data
			# clear canvas
			ctx.clearRect 0, 0, canvas.width, drawHeight

			# draw spectrum lines
			ctx.beginPath()
			# start from rightmost position
			ctx.moveTo drawWidth, drawHeight - heightCoefficient * drawData[drawLeft + drawNumber]
			while drawNumber--
				ctx.lineTo drawNumber * drawZoom,
					drawHeight - heightCoefficient * drawData[drawLeft + drawNumber]
			ctx.strokeStyle = drawColor
			ctx.stroke()

			# draw measuring points if zoom is high enough
			drawNumber = Math.round drawWidth / drawZoom
			if drawZoom > 5 then while drawNumber--
				ctx.beginPath()
				ctx.arc drawNumber * drawZoom,
					drawHeight - heightCoefficient * drawData[drawLeft + drawNumber], 2, 0, 2*Math.PI
				ctx.fillStyle = drawColor
				ctx.fill()

		element.on 'scroll', -> scope.$apply ->
			scope.data.left = element.prop 'scrollLeft'

		element.on 'wheel', (e) -> scope.$apply ->
			oldFactor = scope.zoom.factor
			delta = if e.deltaY < 0 then 1 else -1
			scope.zoom.factor += scope.zoom.step * delta
			updateProps()
			# new data.left position for zooming towards data.current
			scope.data.left = Math.round scope.data.left +
				(scope.zoom.factor / oldFactor - 1) * (scope.data.left + scope.data.current)
			updateLabels scope.data.left
			draw scope.data.left

		# update element and viewer properties if the window size changes and redraw
		$window.addEventListener 'resize', -> scope.$apply ->
			rect = element[0].getBoundingClientRect()
			scope.props.left = rect.left
			scope.props.top = rect.top
			updateProps()
			# prevent scrolling over the new border
			scope.data.left = scope.data.left
			updateLabels scope.data.left
			draw scope.data.left

		# update and redraw if the input data changes
		scope.$watchCollection 'spectrum.data', ->
			scope.data.length = scope.spectrum.data.length 
			updateProps()
			updateLabels scope.data.left
			draw scope.data.left

		# redraw and move inner container when the viewport changes
		scope.$watch 'data.left', (left) ->
			# update scrollLeft in case of manual scrolling
			element.prop 'scrollLeft', left
			scope.innerStyle['transform'] =
				scope.innerStyle['-webkit-transform'] =
					"translateX(#{left}px)"
			updateLabels left
			draw left

		# update the information of the currently hovered position
		scope.$watch 'data.current', (current) -> unless scope.data.length is 0
			scope.indicatorStyle['transform'] =
				scope.indicatorStyle['-webkit-transform'] =
					"translateX(#{current}px)"
			current = Math.round (scope.data.left + current) / scope.zoom.factor
			if current >= scope.data.length then return
			scope.data.label = "#{scope.spectrum.labels[current]}"
			scope.data.value = "#{Math.round scope.spectrum.data[current] / scope.spectrum.maximum * 100}"


	controller: ($scope) ->
		# properties of the spectrum viewer element
		$scope.props =
			# width of the element
			width: 0
			# height of the element
			height: 0
			# left coordinate of the element
			left: 0
			# top coordinate of the element
			top: 0
			# width of the x-axis labels in px
			labelWidth: 200
			# distance between the x-axis labels in px
			labelOffset: 200

		# style of the inner container, that adjusts it's left attribute to
		# be always displayed regardless the scroll position
		$scope.innerStyle =
			'transform': "translateX(0px)"
			'-webkit-transform': "translateX(0px)"

		# style of the bar that marks the mouse position
		$scope.indicatorStyle =
			'transform': "translateX(0px)"
			'-webkit-transform': "translateX(0px)"

		$scope.data =
			# index of the currently hovered position
			current: 0
			# x-axiy value of the currently hovered position
			label: '-'
			# y-axis value of the currently hovered position
			value: '-'
			# number of channels of the dataset
			length: 0
			# the offset of the displayed data (left border of the element)
			_left: 0
			# currently active range (index of ranges array)
			activeRange: -1
		Object.defineProperty $scope.data, 'left',
			# prevent scrolling over left or right border
			set: (x) -> @_left = 
				Math.max 0, Math.min $scope.data.length * $scope.zoom.factor - $scope.props.width, x
			get: -> @_left

		$scope.scroll = 
			# style of the div that makes the spectrum viewer scrollable
			style: width: "0px"
			# start point for manually scrolling by 'grabbing' the viewer
			start: -1
			# value of scrollLeft when manual scrolling has started
			startLeft: 0

		$scope.zoom =
			# distance between the dataset points that are drawn (in px)
			_factor: 1
			# one zoom step increases/decreases the factor by this value
			step: 0.1
			# minimal zoom factor
			min: 0.1
			# maximal zoom factor
			max: 10
		Object.defineProperty $scope.zoom, 'factor',
			# set boundaries for zooming
			set: (x) -> @_factor = Math.max @min, Math.min @max, x
			get: -> @_factor


		# all user made range selections
		$scope.ranges = []

		# all x-axis labels that are displayed
		$scope.labels = []

		$scope.mousedown = (e) -> if e.button is 0
			posX = e.pageX - $scope.props.left
			# start selecting a range
			if $scope.data.activeRange < 0 and e.shiftKey
				$scope.data.activeRange = $scope.ranges.length
				if posX < $scope.props.width then $scope.ranges.push
					start: Math.round ($scope.data.left + posX) / $scope.zoom.factor
					offset: 1
			# start manual scrolling
			else if not e.shiftKey
				$scope.scroll.start = posX
				$scope.scroll.startLeft = $scope.data.left

		$scope.mousemove = (e) ->
			posX = e.pageX - $scope.props.left
			if posX > $scope.props.width then return

			$scope.data.current = posX

			# update active range
			unless $scope.data.activeRange < 0
				range = $scope.ranges[$scope.data.activeRange]
				offset = Math.round ($scope.data.left + posX) / $scope.zoom.factor - range.start
				# minimal offset is 1 (one chanel selected)
				range.offset = Math.max offset, 1

			# scroll
			unless $scope.scroll.start < 0
				$scope.data.left = $scope.scroll.startLeft + $scope.scroll.start - posX

		$scope.mouseup = ->
			$scope.$emit 'spectrumViewer.rangesUpdated' if $scope.data.activeRange >= 0
			# end range selecting
			$scope.data.activeRange = -1
			# end manual scrolling
			$scope.scroll.start = -1

		$scope.removeRange = (index) ->
			$scope.ranges.splice index, 1
			$scope.$emit 'spectrumViewer.rangesUpdated'

		return
		