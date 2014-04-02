# service for storing the spectrum ranges and providing the updating functions
angular.module('quimbi').service 'ranges', (selection, toolset, input, settings, Tool) ->

	channelMask = new Uint8Array selection.textureDimension * selection.textureDimension * 4

	# storing the spectrum ranges
	@array = []

	@remove = (index) => @array.splice index, 1

	# updates the channelMask filter according to the selected ranges in the
	# spectrum viewer
	updateDistanceRanges = =>
		# number of overall channels padded to be represented as vec4's
		channel = input.files.length * 4
		# number of active channels of this channel mask
		activeChannels = 0

		hasActiveRange = no
		for range in @array when range.active
			hasActiveRange = yes
			break

		if hasActiveRange
			# clear mask
			channelMask[channel] = 0 while channel--

			# if the group argument exists, take only the ranges of this group
			# otherwise take all
			for range in @array when range.active
				offset = range.offset
				while offset--
					channelMask[range.start + offset] = 255
					activeChannels++
		else
			activeChannels = input.channels
			channelMask[channel] = 255 while channel--

		toolset.updateDistancesChannelMask channelMask, activeChannels

	updateMeanRanges = =>
		hasActiveRange = no
		for range in @array when range.active
			hasActiveRange = yes
			break

		for group in Tool.groups
			# number of overall channels padded to be represented as vec4's
			channel = input.files.length * 4
			# number of active channels of this channel mask
			activeChannels = 0
			
			if hasActiveRange
				# clear mask
				channelMask[channel] = 0 while channel--

				# if the group argument exists, take only the ranges of this group
				# otherwise take all
				for range in @array when range.active and range.group is group
					offset = range.offset
					while offset--
						channelMask[range.start + offset] = 255
						activeChannels++
			else
				activeChannels = input.channels
				channelMask[channel] = 255 while channel--

			toolset.updateMeanChannelMask channelMask, activeChannels, group

	@update = -> switch settings.displayMode
		when 'mean' then updateMeanRanges()
		else updateDistanceRanges()

	return