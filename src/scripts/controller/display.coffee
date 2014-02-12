# controller for the display route
angular.module('quimbi').controller 'displayCtrl', ($scope, settings, input, shader) ->
	$scope.properties.disableAbout = no

	# manage image overlay inside the canvasWrapper
	$scope.overlay =
		show: settings.showOverlay and input.overlayImage isnt ''
		src: input.overlayImage
		opacity: settings.overlayOpacity

	updateOverlayOpacity = (newOpacity) -> settings.overlayOpacity = newOpacity
	$scope.$watch 'overlay.opacity', updateOverlayOpacity

	# information about the hovered pixel
	$scope.colorRatio =
		show: settings.showColorRatio
		# pixel array for webgl
		pixel: new Uint8Array 4
		# percentage of color contribution formatted for css
		r: '0%'
		g: '0%'
		b: '0%'
		white: '0%'
		black: '0%'

	updatePixel = (newPixel) ->
		ratio = $scope.colorRatio
		r = newPixel[0]
		g = newPixel[1]
		b = newPixel[2]
		rgb = r + g + b
		if r is g and r is b and g is b
			ratio.r = ratio.g = ratio.b = '0%'
			# no division by zero
			w = if rgb is 0 then 0 else r / 255
			ratio.white = "#{100 * w}%"
			ratio.black = "#{100 * (1 - w)}%"
		else
			ratio.white = ratio.black = '0%'
			ratio.r = "#{100 * r / rgb}%"
			ratio.g = "#{100 * g / rgb}%"
			ratio.b = "#{100 * b / rgb}%"
	$scope.$watch 'colorRatio.pixel', updatePixel, yes
	return