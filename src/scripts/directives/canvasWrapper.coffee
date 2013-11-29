angular.module('quimbi').directive 'canvasWrapper', (canvas, $window, toolset) ->
	
	restrict: 'A'

	templateUrl: 'templates/canvasWrapper.html'

	replace: yes

	scope: yes

	link: (scope, element, attrs) ->
		element.prepend canvas.element
		scope.properties = {}

		# updates the information about the canvasWrapper element
		# needed for calculating the relative mouse position
		updateProperties = -> 
			rect = element[0].getBoundingClientRect()
			properties = scope.properties
			properties.left = rect.left
			properties.top = rect.top
			properties.width = element[0].clientWidth
			properties.height = element[0].clientHeight
			# TODO make downscaling of canvas dimensions possible
			#canvas.checkScale properties.width

		# observe resizer width
		observer = new MutationObserver updateProperties
		observer.observe element[0].querySelector('.resizer'), attributes: yes
		updateProperties()
		return

	controller: ($scope) ->
		# mouse coordinates in % of the canvasWrapper dimensions
		mouse =
			x: 0
			y: 0
		
		gl = mvi.getContext()
		glMousePosition = gl.getUniformLocation mvi.getProgram(), "u_currpos"

		# updates shader variable of mouse position and returns render state
		prerenderCallabck = -> 
			gl.uniform2f glMousePosition, mouse.x, 1 - mouse.y
			toolset.getRenderState()
		mvi.setPrerenderCallback prerenderCallabck

		# updates mouse coordinates
		$scope.mousemove = (e) ->
			mouse.x = (e.pageX - $scope.properties.left) / $scope.properties.width
			mouse.y = (e.pageY - $scope.properties.top) / $scope.properties.height
			#console.log "#{mouse.x} x #{mouse.y}"

		$scope.click = (e) -> toolset.drawn
			x: mouse.x
			y: mouse.y

		# test? is default tool active by default?
		# mvi.startRendering()
		return