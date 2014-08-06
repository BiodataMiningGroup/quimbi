# manages all existing markers and provides functions to manipulate them
angular.module('quimbi').service 'renderer', (input, mouse, markers, ranges, regions, settings, shader, colorMap, C, $rootScope) ->

	# array with one entry for each channel of the dataset.
	# channels that should be discarded are 0 and the others 1
	channelMask = new Uint8Array input.getChannelTextureDimension() *
		input.getChannelTextureDimension() * 4

	# determines, which color channels should be shown on the canvas
	passiveColorMask = [0, 0, 0]

	# determines which color channel should be updated with the distance or
	# mean calculations
	activeColorMask = [0, 0, 0]

	# final color mask for the direct display mode
	directColorMask = [1, 0, 0]

	# indext of the previously rendered channel in the direct display mode
	renderedDirectChannel = 0
	# index of the current channel to render in the direct display mode
	directChannel = 0

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

			for range in rangesList when range.isActive()
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
			glmvilib.render shader.getActive()...
		$rootScope.$broadcast 'renderer.updated'

	# updates the channel mask and re-renders for each ranges group
	# separately
	updateMeanChannelMask = ->
		groups = ranges.byGroup()

		clearArray passiveColorMask
		passiveColorMask[group] = 1 for group of groups
		shader.setPassiveColorMask passiveColorMask
		# clears image if there are no ranges
		glmvilib.render shader.getFinal()...

		for group, rangesList of groups
			updateChannelMaskWith rangesList
			clearArray activeColorMask
			activeColorMask[group] = 1
			shader.setActiveColorMask activeColorMask
			glmvilib.render shader.getActive()...
		$rootScope.$broadcast 'renderer.updated'

	@update = ->
		switch settings.displayMode
			when C.DISPLAY_MODE.MEAN then updateMeanChannelMask()
			when C.DISPLAY_MODE.DIRECT
				# do not render the same channel twice
				if renderedDirectChannel is directChannel then return
				renderedDirectChannel = directChannel
				shader.updateDirectChannel renderedDirectChannel
				glmvilib.render shader.getActive()...
			when C.DISPLAY_MODE.SIMILARITY
				# do not render when no marker is active
				if not markers.hasActive() then return
				shader.setPassiveColorMask updatePassiveColorMask()
				shader.setActiveColorMask updateActiveColorMask()
				glmvilib.render shader.getActive()...
		$rootScope.$broadcast 'renderer.updated'

	@updateFinal = ->
		switch settings.displayMode
			when C.DISPLAY_MODE.MEAN then updateMeanChannelMask()
			when C.DISPLAY_MODE.DIRECT
				shader.setPassiveColorMask directColorMask
				shader.setActiveColorMask directColorMask
				glmvilib.render shader.getActive()...
			when C.DISPLAY_MODE.SIMILARITY
				shader.setPassiveColorMask updatePassiveColorMask()
				glmvilib.render shader.getFinal()...
		$rootScope.$broadcast 'renderer.updated'

	@updateChannelMask = ->	switch settings.displayMode
		when C.DISPLAY_MODE.MEAN then updateMeanChannelMask()
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

	# updates the direct channel
	@updateDirectChannel = (channel) ->
		directChannel = channel

	return
