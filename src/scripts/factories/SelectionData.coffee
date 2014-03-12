# data structure for storing and quickly accessing the data of a selection
angular.module('quimbi').factory 'SelectionData', (input) ->
	# constructor function gets the Uint8Array of intensity values
	(intensities) ->
		# get length from input because intensities can have more entries as there
		# are channels
		length = Math.min intensities.length, input.channels

		# array with intensity value [0..255] as first dimension and channel index
		# (of input.channelNames) as second dimension. so the channels are grouped
		# by intensity
		@byValue = []
		# fill with empty arrays
		@byValue.push [] for i in [0..255]

		# array with the channels intensity value at the respective index of the
		# channel (of input.channelNames)
		@byName = new Array length

		# fill @byName and find max/min values
		channel = length
		@byName[channel] = intensities[channel] while channel--

		# fill @byValue
		@byName.forEach (value, index) => @byValue[value].push index

		return