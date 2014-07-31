angular.module('quimbi').service 'colorScaleHistogram', (framebuffer) ->
	# the intensity histogram for every channel
	histogram = [
		new Array 256
		new Array 256
		new Array 256
	]

	clear = -> for channel in [0...3]
		histogram[channel][i] = 0 for i in [0...histogram[channel].length]

	@get = ->
		clear()
		intensities = framebuffer.getIntensities()
		for intensityIndex in [0...intensities.length] by 4
			# ignore intensities with alpha == 0
			if intensities[intensityIndex + 3] is 0 then continue

			for channel, channelIndex in histogram
				histogram[channelIndex][intensities[intensityIndex + channelIndex]]++
		histogram

	return
