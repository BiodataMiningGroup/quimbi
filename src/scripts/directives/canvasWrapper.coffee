# directive for the canvas wrapper element in the display route.
# this could be just a controller, too, but the canvas has to be appended to
# the DOM so an "element" is needed.
# updates the mouse position on the canvas
angular.module('quimbi').directive 'canvasWrapper', (canvas, toolset, settings, mouse) ->
	
	restrict: 'A'

	templateUrl: 'templates/canvasWrapper.html'

	replace: yes

	scope: yes

	link: (scope, element) ->
		# important! because of this the canvasWrapper is a directive and not just a controller
		element.prepend canvas.element
		# set saved element width if one was saved
		if settings.canvasWidth > 0 then element.css 'width', "#{settings.canvasWidth}px"
		# information about the canvasWrapper element
		scope.properties = 
			left: 0
			top: 0
			width: 0
			height: 0

		# updates the information about the canvasWrapper element
		# needed for calculating the relative mouse position
		# TODO: doesn't get called in Chrome
		updateProperties = ->
			rect = element[0].getBoundingClientRect()
			properties = scope.properties
			properties.left = rect.left
			properties.top = rect.top
			properties.width = element[0].clientWidth
			properties.height = element[0].clientHeight
			# console.log properties

		# observe element+children
		# TODO: doesn't work in Chrome
		observer = new MutationObserver updateProperties
		observer.observe element[0], attributes: yes
		# update once on linking
		updateProperties()

		updateWidth = (newWidth) ->
			settings.canvasWidth = newWidth
			canvas.checkScale newWidth
		scope.$watch 'properties.width', updateWidth
		return

	controller: ($scope) ->		
		# updates mouse coordinates and reads current pixel data
		$scope.mousemove = (e) ->
			mouse.position.x = (e.pageX - $scope.properties.left) / $scope.properties.width
			mouse.position.y = (e.pageY - $scope.properties.top) / $scope.properties.height
			unless settings.showColorRatio then return

			pos = canvas.getPixelPosition mouse.position.x, 1 - mouse.position.y
			# x-position, y-position, x-dimension, y-dimension, color format, 
			# number format, destination variable. colorRatio is from parent scope
			#gl.readPixels pos.x, pos.y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, $scope.colorRatio.pixel

		# finishes drawing/selecting of the currently active tool at the current
		# mouse position
		$scope.drawn = -> toolset.drawn x: mouse.position.x, y: mouse.position.y

		# TODO is default tool active by default?
		return