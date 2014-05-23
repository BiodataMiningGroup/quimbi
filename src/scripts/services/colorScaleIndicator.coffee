angular.module('quimbi').service 'colorScaleIndicator', (mouse, shader) ->

	intensities = new Uint8Array 4

	normalizedIntensities = [0, 0, 0, 0]

	color = new Uint8Array 4

	@getIntensities = ->
		glmvilib.render shader.getIntensity()
		glmvilib.getPixels mouse.position.xPx, mouse.position.yPx, 1, 1, intensities
		intensities

	@getColor = ->
		glmvilib.render shader.getFinal()
		glmvilib.getPixels mouse.position.xPx, mouse.position.yPx, 1, 1, color
		color

	# normalizes the color channel intensities so r+g+b=1
	@getNormalizedIntensities = ->
		sum = intensities[0] + intensities[1] + intensities[2]
		for intensity, index in intensities
			normalizedIntensities[index] = if sum is 0 then 1 / 3 else intensity / sum
		normalizedIntensities
	
	return
