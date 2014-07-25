angular.module('quimbi').service 'colorScaleIndicator', (mouse, shader, colorConverter) ->

	intensities = new Uint8Array 4

	normalizedIntensities = [0, 0, 0, 0]

	colorBytes = new Uint8Array 4

	colorRGB = [0, 0, 0]

	@update = ->
		glmvilib.render shader.getIntensity()
		glmvilib.getPixels mouse.position.dataX, mouse.position.dataY, 1, 1, intensities
		glmvilib.render shader.getColor()
		glmvilib.getPixels mouse.position.dataX, mouse.position.dataY, 1, 1, colorBytes
		colorRGB = colorConverter.rgbFromLchBytes colorBytes...

	@getIntensities = -> intensities

	@getColor = -> colorRGB

	# normalizes the color channel intensities so r+g+b=1
	@getNormalizedIntensities = ->
		sum = intensities[0] + intensities[1] + intensities[2]
		for intensity, index in intensities
			normalizedIntensities[index] = if sum is 0 then 1 / 3 else intensity / sum
		normalizedIntensities

	return
