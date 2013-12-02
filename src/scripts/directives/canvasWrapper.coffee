# directive for the canvas wrapper element in the display route.
# this could be just a controller, too, but the canvas has to be appended to
# the DOM so an "element" is needed.
# manages the mouse position on the canvas and therefore defines the
# mvi prerenderCallback. manages other mouse events on the canvas, too.
angular.module('quimbi').directive 'canvasWrapper', (canvas, $window, toolset) ->
	
	restrict: 'A'

	templateUrl: 'templates/canvasWrapper.html'

	replace: yes

	scope: yes

	link: (scope, element, attrs) ->
		# important! because of this the canvasWrapper is a directive and not just a controller
		element.prepend canvas.element
		# information about the canvasWrapper element
		scope.properties = 
			left: 0
			top: 0
			width: 0
			height: 0

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

		# observe element+children
		observer = new MutationObserver updateProperties
		observer.observe element[0],
			attributes: yes
			subtree: yes
		# update once on linking
		updateProperties()
		return

	controller: ($scope) ->
		# mouse coordinates in % of the canvasWrapper dimensions
		mouse =
			x: 0
			y: 0
		
		gl = mvi.getContext()
		glMousePosition = gl.getUniformLocation mvi.getProgram(), "u_currpos"

		# updates shader variable of the mouse position and returns render state
		# obtained from the toolset
		prerenderCallabck = -> 
			gl.uniform2f glMousePosition, mouse.x, 1 - mouse.y
			toolset.getRenderState()
		mvi.setPrerenderCallback prerenderCallabck

		# updates mouse coordinates
		$scope.mousemove = (e) ->
			mouse.x = (e.pageX - $scope.properties.left) / $scope.properties.width
			mouse.y = (e.pageY - $scope.properties.top) / $scope.properties.height

		# finishes drawing/selecting of the currently active tool at the current
		# mouse position
		$scope.drawn = -> toolset.drawn
			x: mouse.x
			y: mouse.y

		# is default tool active by default?
		# mvi.startRendering()
		return