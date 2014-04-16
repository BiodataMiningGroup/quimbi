# manages all existing markers and provides functions to manipulate them
angular.module('quimbi').service 'renderer', (input, mouse, markers, ranges, regions, settings, shader) ->

	channelMask = new Uint8Array input.getChannelTextureDimension() *
		input.getChannelTextureDimension() * 4

	regionMask = null

	renderPromise = null

	passiveColorMask = [0, 0, 0]

	activeColorMask = [0, 0, 0]

	clearArray = (array) ->
		array[index] = 0 for index in [0...array.length]
		array

	updatePassiveColorMask = ->
		clearArray passiveColorMask
		passiveColorMask[m.getColorMaskIndex()] = 1 for m in markers.getList()
		passiveColorMask

	updateActiveColorMask = ->
		clearArray activeColorMask
		activeColorMask[markers.getList()[markers.getActiveIndex()].getColorMaskIndex()] = 1
		activeColorMask

	updateChannelMaskWith = (rangesList) ->
		# number of overall channels padded to be represented as vec4's
		channel = input.files.length * 4

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

	updateDistancesChannelMask = ->
		updateChannelMaskWith ranges.list

		for marker in markers.getList() when marker.isSet()
			clearArray activeColorMask
			activeColorMask[marker.getColorMaskIndex()] = 1
			shader.setActiveColorMask activeColorMask
			angular.extend mouse.position, marker.getPosition()
			glmvilib.render.apply glmvilib, shader.getActive()

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

	updateColorMaps = ->
		maps = []
		for marker in markers.getList()
			maps[marker.getColorMaskIndex()] = marker.getColorMap()
		shader.updateColorMaps maps

	@update = =>
		#TODO
		updateColorMaps()
		if settings.displayMode is 'mean'
			@updateChannelMask()
		else
			shader.setPassiveColorMask updatePassiveColorMask()
			if markers.hasActive()
				shader.setActiveColorMask updateActiveColorMask()
				renderPromise = glmvilib.renderLoop.apply glmvilib, shader.getActive()
			else if renderPromise?
				renderPromise.stop()
				renderPromise = null
			else
				glmvilib.render shader.getFinal()

	@updateChannelMask = ->	switch settings.displayMode
		when 'mean' then updateMeanChannelMask()
		else updateDistancesChannelMask()

	@updateRegionMask = =>
		shader.updateRegionMask regions.getRegionMask()
		# re-renders the image
		@updateChannelMask()
	
	return
