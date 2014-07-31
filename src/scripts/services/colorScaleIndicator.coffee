angular.module('quimbi').service 'colorScaleIndicator', (framebuffer, colorConverter) ->

	normalizedIntensities = [0, 0, 0]

	@getIntensities = -> framebuffer.getMouseIntensities()

	@getColor = ->
		colorConverter.rgbFromLchBytes framebuffer.getMouseColors()...

	# normalizes the color channel intensities so r+g+b=1
	@getNormalizedIntensities = ->
		intensities = framebuffer.getMouseIntensities()
		sum = intensities[0] + intensities[1] + intensities[2]
		if sum is 0 then for index in [0...normalizedIntensities.length]
			normalizedIntensities[index] = 1/3
		else for index in [0...normalizedIntensities.length]
			normalizedIntensities[index] = intensities[index] / sum
		normalizedIntensities

	return
