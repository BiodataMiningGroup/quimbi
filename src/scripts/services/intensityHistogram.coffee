angular.module('quimbi').service 'intensityHistogram', (input, shader) ->

	# the raw pixel data
	intensities = new Uint8Array input.dataWidth * input.dataHeight * 4

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

	# ATTENTION:
	# assumes the rgb framebuffer of the rgb-selection shader to be bound!
	# must be as fast as possible
	@update = ->
		glmvilib.getPixels 0, 0, input.dataWidth, input.dataHeight, intensities
		clear()
		for intensityIndex in [0...intensities.length] by 4
			# ignore pixels with alpha == 0
			if intensities[intensityIndex + 3] is 0 then continue

			for channel, channelIndex in histogram
				tmpIntensity = intensities[intensityIndex + channelIndex]
				# build histogram
				histogram[channelIndex][tmpIntensity]++
				# find bounds
				tmpBund = channelBounds[channelIndex].max
				channelBounds[channelIndex].max = Math.max tmpBund, tmp
				tmpBund = channelBounds[channelIndex].min
				channelBounds[channelIndex].min = Math.min tmpBund, tmp

	@get = -> histogram

	return
