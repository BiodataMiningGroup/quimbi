angular.module('quimbi').service 'colorScaleIndicator', (framebuffer, colorConverter) ->

	normalizedIntensities = [0, 0, 0, 0]

	@getIntensities = -> framebuffer.getMouseIntensities()

	@getColor = ->
		colorConverter.rgbFromLchBytes framebuffer.getMouseColors()...

	# normalizes the color channel intensities so r+g+b=1
	@getNormalizedIntensities = =>
		intensities = @getIntensities()
		sum = intensities[0] + intensities[1] + intensities[2]
		# equal distribution in this case
		sum = 3 if sum is 0
		for index in [0...3]
			normalizedIntensities[index] = intensities[index] / sum
		normalizedIntensities[3] = intensities[3] / 255
		normalizedIntensities

	return
