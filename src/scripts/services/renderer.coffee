# manages all existing markers and provides functions to manipulate them
angular.module('quimbi').service 'renderer', (input, mouse, markers, ranges, regions, settings, shader, colorMap) ->

	# array with one entry for each channel of the dataset.
	# channels that should be discarded are 0 and the others 1
	channelMask = new Uint8Array input.getChannelTextureDimension() *
		input.getChannelTextureDimension() * 4

	# determines, which color channels should be shown on the canvas
	passiveColorMask = [0, 0, 0]

	# determines which color channel should be updated with the distance or
	# mean calculations
	activeColorMask = [0, 0, 0]

	# sets all entries of the given array to 0
	clearArray = (array) ->
		array[index] = 0 for index in [0...array.length]
		array

	# updates the passive color mask according to the marker configuration
	updatePassiveColorMask = ->
		clearArray passiveColorMask
		passiveColorMask[m.getIndex()] = 1 for m in markers.getList()
		passiveColorMask

	# updates the active color mask according to the marker configuration
	updateActiveColorMask = ->
		clearArray activeColorMask
		activeColorMask[markers.getListAll()[markers.getActiveIndex()].getIndex()] = 1
		activeColorMask

	# updates the channel mask array with the given list of spectrum ranges
	# and passes it on to the shader service to update the channel mask texture
	updateChannelMaskWith = (rangesList) ->
		channel = input.channels

		# number of active channels of the channel mask
		activeChannels = 0

		if ranges.hasActive()
			# clear mask
			channelMask[channel] = 0 while channel--

			for range in rangesList when range.active
				offset = range.offset
				activeChannels += offset
				channelMask[range.start + offset] = 255 while offset--
		else
			activeChannels = input.channels
			channelMask[channel] = 255 while channel--

		shader.updateChannelMask channelMask, activeChannels
		channelMask

	# updates the channel mask array with all ranges, regardless their group
	# and re-renders the dustances for every marker
	updateDistancesChannelMask = ->
		updateChannelMaskWith ranges.list

		for marker in markers.getList() when marker.isSet()
			clearArray activeColorMask
			activeColorMask[marker.getIndex()] = 1
			shader.setActiveColorMask activeColorMask
			angular.extend mouse.position, marker.getPosition()
			glmvilib.render.apply glmvilib, shader.getActive()

	# updates the channel mask and re-renders for each ranges group
	# separately
	updateMeanChannelMask = ->
		groups = ranges.byGroup()

		clearArray passiveColorMask
		passiveColorMask[group] = 1 for group of groups
		shader.setPassiveColorMask passiveColorMask
		# clears image if there are no ranges
		glmvilib.render shader.getFinal()

		for group, rangesList of groups
			updateChannelMaskWith rangesList
			clearArray activeColorMask
			activeColorMask[group] = 1
			shader.setActiveColorMask activeColorMask
			glmvilib.render.apply glmvilib, shader.getActive()

	@update = => switch settings.displayMode
		when 'mean' then @updateChannelMask()
		else
			shader.setPassiveColorMask updatePassiveColorMask()
			if markers.hasActive()
				shader.setActiveColorMask updateActiveColorMask()
				glmvilib.render.apply glmvilib, shader.getActive()
			else
				glmvilib.render shader.getFinal()

	@updateChannelMask = ->	switch settings.displayMode
		when 'mean' then updateMeanChannelMask()
		else updateDistancesChannelMask()

	@updateRegionMask = =>
		shader.updateRegionMask regions.getRegionMask()
		# re-renders the image
		@updateChannelMask()

	# updates the color map textures with the currently selected color maps
	@updateColorMaps = ->
		maps = []
		for name, index in settings.activeColorMaps
			maps[index] = colorMap.get name
		shader.updateColorMaps maps
		
	return
