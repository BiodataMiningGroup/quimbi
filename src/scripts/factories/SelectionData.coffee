# data structure for storing and quickly accessing the data of a selection
angular.module('quimbi').factory 'SelectionData', (input) ->
	# constructor function gets the Uint8Array of intensity values
	(intensities) ->
		@maxIntensity = -Infinity
		@minIntensity = Infinity

		# array with intensity value [0..255] as first dimension and channel index
		# (of input.channelNames) as second dimension. so the channels are grouped
		# by intensity
		@byValue = []
		# fill with empty arrays
		@byValue.push [] for i in [0..255]

		# array with the channels intensity value at the respective index of the
		# channel (of input.channelNames)
		@byName = new Array input.channels

		# fill @byName and find max/min values
		channel = input.channels
		while channel--
			value = @byName[channel] = intensities[channel]
			@maxIntensity = value if value > @maxIntensity
			@minIntensity = value if value < @minIntensity

		# fill @byValue
		@byName.forEach (value, index) => @byValue[value].push index

		return