angular.module('quimbi').service 'colorScaleHistogram', (framebuffer) ->
	# the intensity histogram for every channel
	histogram = [
		new Array 256
		new Array 256
		new Array 256
	]

	# the temporary intensity value to build the histogram
	tmpIntensity = 0
	# the temporary value to find the channel bounds
	tmpBound = 0

	# contains the maximum and minimum occuring intensity values of the rgb
	# channels of the current image
	channelBounds = [
		{max: 0, min: 255}
		{max: 0, min: 255}
		{max: 0, min: 255}
	]

	clear = -> for channel in [0...3]
		histogram[channel][i] = 0 for i in [0...histogram[channel].length]
		channelBounds[channel].max = 0
		channelBounds[channel].min = 255

	@get = ->
		clear()
		intensities = framebuffer.getIntensities()
		for intensityIndex in [0...intensities.length] by 4
			# ignore pixels with alpha == 0
			if intensities[intensityIndex + 3] is 0 then continue

			for channel, channelIndex in histogram
				tmpIntensity = intensities[intensityIndex + channelIndex]
				# build histogram
				histogram[channelIndex][tmpIntensity]++
				# find bounds
				tmpBund = channelBounds[channelIndex].max
				channelBounds[channelIndex].max = Math.max tmpBund, tmpIntensity
				tmpBund = channelBounds[channelIndex].min
				channelBounds[channelIndex].min = Math.min tmpBund, tmpIntensity
		histogram

	return
