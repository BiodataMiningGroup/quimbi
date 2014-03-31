# directive to show a large dataset as spectrogram
angular.module('quimbi').directive 'spectrumViewer', ($window) ->
	
	restrict: 'A'

	templateUrl: './templates/spectrumViewer.html'

	replace: yes

	scope: 
		# layers {data: [], color: ''}, labels, maximum, minimum, length
		spectrum: '=spectrumViewer'
		# array of {start: Number, offset: Number} objects
		ranges: '=spectrumRanges'

	link: (scope, element) ->
		# update viewer properties
		updateProps = ->
			scope.props.width = element.prop 'clientWidth'
			scope.props.height = element.prop('clientHeight') - 25 #25px label height
			if scope.spectrum.length is 0 then return

			scope.zoom.min = scope.props.width / scope.spectrum.length
			# also checks if current zoom.factor is smaller than the new zoom.min
			scope.zoom.factor = scope.zoom.factor

			# minimal number is 1
			scope.labels.length = Math.ceil scope.props.width / scope.props.labelWidth

		# update the displayed x-axis labels
		updateLabels = (left) ->
			spectrumLabels = scope.spectrum.labels
			# index of leftmost visible point
			left = Math.round left / scope.zoom.factor
			# number of labels to display
			number = scope.labels.length
			# index offset of the datapoints that get a label
			offset = Math.round scope.props.width / (scope.zoom.factor * number)
			# pixel offset of the displayed labels
			scope.props.labelOffset = offset * scope.zoom.factor
			scope.labels[number] = spectrumLabels[left + number * offset] while number--

		# update element and viewer properties if the window size changes and redraw
		updateResize = ->
			rect = element[0].getBoundingClientRect()
			scope.props.left = rect.left
			scope.props.top = rect.top
			updateProps()
			# prevents scrolling over the new border
			scope.data.left = scope.data.left
			updateLabels scope.data.left

		$window.addEventListener 'resize', -> scope.$apply updateResize
		# initially update once
		updateResize()

		element.on 'scroll', -> scope.$apply ->
			scope.data.left = element.prop 'scrollLeft'

		element.on 'wheel', (e) ->
			# remove jquery event wrapper
			e = e.originalEvent or e
			unless e.deltaY is 0 then scope.$apply ->
				oldFactor = scope.zoom.factor
				delta = if e.deltaY < 0 then 1 else -1
				scope.zoom.factor += scope.zoom.step * delta
				updateProps()
				# new data.left position for zooming towards data.current
				scope.data.left = Math.round scope.data.left +
					(scope.zoom.factor / oldFactor - 1) * (scope.data.left + scope.data.current)			

		# update and redraw if the input data changes
		updateData = (data) ->
			updateProps()
			updateLabels scope.data.left
		scope.$watch 'spectrum.length', updateData

		# redraw and move inner container when the viewport changes
		scope.$watch 'data.left', (left) ->
			# update scrollLeft in case of manual scrolling
			element.prop 'scrollLeft', left
			scope.innerStyle['transform'] =
				scope.innerStyle['-webkit-transform'] =
					"translateX(#{left}px)"
			updateLabels left

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
			# map of y-axis values of the currently hovered position
			values: {}
			# number of channels of the dataset
			length: 0
			# the offset of the displayed data (left border of the element)
			_left: 0
			# currently active range (index of ranges array)
			activeRange: -1
			# number of layers currently displayed
			layers: 0

		Object.defineProperty $scope.data, 'left',
			# prevent scrolling over left or right border
			set: (x) -> @_left = 
				Math.max 0, Math.min $scope.spectrum.length * $scope.zoom.factor - $scope.props.width, x
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

		# properties to pass on to the layer canvas directives
		$scope.layerProps =
			width: 0
			height: 0
			zoom: 0
			left: 0
			maximum: 0
		$scope.$watch 'props.width', (width) -> $scope.layerProps.width = width
		$scope.$watch 'props.height', (height) -> $scope.layerProps.height = height
		$scope.$watch 'zoom.factor', (zoom) -> $scope.layerProps.zoom = zoom
		$scope.$watch 'data.left', (left) -> $scope.layerProps.left = left
		$scope.$watch 'spectrum.maximum', (maximum) -> $scope.layerProps.maximum = maximum

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
					active: yes
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
			# end range selecting
			$scope.data.activeRange = -1
			# end manual scrolling
			$scope.scroll.start = -1

		# update the information of the currently hovered position
		$scope.$watch 'data.current', (current) -> unless $scope.spectrum.length is 0
			$scope.indicatorStyle['transform'] =
				$scope.indicatorStyle['-webkit-transform'] =
					"translateX(#{current}px)"
			current = Math.round ($scope.data.left + current) / $scope.zoom.factor
			if current >= $scope.spectrum.length then return
			$scope.data.label = "#{$scope.spectrum.labels[current]}"
			for id, layer of $scope.spectrum.layers
				$scope.data.values[id] = Math.round layer.data[current] / $scope.spectrum.maximum * 100

		# update the number of currently displayed layers
		$scope.$watchCollection 'spectrum.layers', (layers) ->
			$scope.data.layers = 0
			$scope.data.layers++ for layer of layers

		$scope.$on 'spectrumViewer.focusRange', (e, index) ->
			range = $scope.ranges[index]
			# center position of the range minus half of the viewer-width
			$scope.data.left = Math.round ((2 * range.start + range.offset) * $scope.zoom.factor - $scope.props.width) / 2

		return
		