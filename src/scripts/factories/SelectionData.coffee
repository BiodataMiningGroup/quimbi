# data structure for storing and quickly accessing raw pixel/channel data
angular.module('quimbi').factory 'SelectionData', (input) ->

	class SelectionData

		constructor: ->

			# array with intensity value [0, 255] as first dimension and channel index
			# (of input.channelNames) as second dimension. so the channels are grouped
			# by intensity
			@histogram = []
			# fill with empty arrays
			@histogram.push 0 for i in [0..255]

			# array with the channel's intensity value at the respective index of the
			# channel (of input.channelNames)
			@spectrogram = new Uint8Array input.getChannelTextureDimension() *
				input.getChannelTextureDimension() * 4