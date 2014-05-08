angular.module('quimbi').service 'colorScaleHistogram', (input, shader) ->

	# the raw pixel data
	intensities = new Uint8Array input.width * input.height * 4

	# the intensity histogram for every channel
	histogram = [
		new Array 256
		new Array 256
		new Array 256
	]

	red = green = blue = 0

	clearHistogram = ->
		for channel in histogram
			channel[i] = 0 for i in [0...channel.length]

	updateIntensities = ->
		glmvilib.render shader.getIntensity()
		glmvilib.getPixels 0, 0, input.width, input.height, intensities
		intensities

	@get = ->
		clearHistogram()
		updateIntensities()
		for index in [0...intensities.length] by 4
			red = intensities[index]
			green = intensities[index + 1]
			blue = intensities[index + 2]
			# ignore 0 pixels
			if red is 0 and green is 0 and blue is 0 then continue
			histogram[0][red]++
			histogram[1][green]++
			histogram[2][blue]++
		histogram
	
	return
