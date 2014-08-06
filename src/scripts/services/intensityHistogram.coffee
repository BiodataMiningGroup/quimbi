angular.module('quimbi').service 'intensityHistogram', (framebuffer) ->
	# the intensity histogram for every channel
	histogram = [
		new Array 256
		new Array 256
		new Array 256
	]

	# contains the maximum and minimum occuring intensity values of the rgb
	# channels of the current image
	channelBounds = [
		{max: 0, min: 1}
		{max: 0, min: 1}
		{max: 0, min: 1}
	]

	clearHistogram = -> for channel in histogram
		channel[i] = 0 for i in [0...channel.length]

	updateChannelBounds = ->
		for values, channelIndex in histogram
			for value, index in values when value isnt 0
				channelBounds[channelIndex].min = index / 255
				break

			for value, index in values by -1 when value isnt 0
				channelBounds[channelIndex].max = index / 255
				break
		channelBounds

	updateHistogram = ->
		clearHistogram()
		intensities = framebuffer.getIntensities()
		for intensityIndex in [0...intensities.length] by 4
			# ignore intensities with alpha == 0
			if intensities[intensityIndex + 3] is 0 then continue

			for channelIndex in [0...histogram.length]
				histogram[channelIndex][intensities[intensityIndex + channelIndex]]++
		histogram

	# returns the channel bounds not the histogram!
	@update = ->
		updateHistogram()
		updateChannelBounds()

	@getChannelBounds = -> channelBounds

	@get = -> histogram

	return
