angular.module('quimbi').service 'colorScaleIndicator', (mouse, shader) ->

	intensities = new Uint8Array 4

	@getIntensities = ->
		glmvilib.render shader.getIntensity()
		glmvilib.getPixels mouse.position.xPx, mouse.position.yPx, 1, 1, intensities
		intensities
	
	return
