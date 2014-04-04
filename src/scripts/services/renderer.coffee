# manages all existing markers and provides functions to manipulate them
angular.module('quimbi').service 'renderer', (input, marker, settings, shader) ->

	channelMask = new Uint8Array input.getChannelTextureDimension() *
		input.getChannelTextureDimension() * 4

	regionMask = null

	renderPromise = null

	passiveColorMask = [0, 0, 0]

	activeColorMask = [0, 0, 0]

	updatePassiveColorMask = ->
		passiveColorMask[index] = 0 for index in [0...passiveColorMask.length]
		passiveColorMask[m.getColorMaskIndex()] = 1 for m in marker.list
		passiveColorMask

	updateActiveColorMask = ->
		activeColorMask[index] = 0 for index in [0...activeColorMask.length]
		activeColorMask[marker.list[marker.getActiveIndex()].getColorMaskIndex()] = 1
		activeColorMask


	@update = ->
		shader.setPassiveColorMask updatePassiveColorMask()
		if marker.hasActive()
			shader.setActiveColorMask updateActiveColorMask()
			renderPromise = glmvilib.renderLoop.apply glmvilib, shader.getActive()
		else if renderPromise?
			renderPromise.stop()
			renderPromise = null
		else
			glmvilib.render shader.getFinal()

	@updateChannelMask = ->
		channelMask[index] = 255 for index in [0...channelMask.length]
		shader.updateChannelMask channelMask, input.channels

	@updateRegionMask = ->
	
	return
