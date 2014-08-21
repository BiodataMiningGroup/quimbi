# service for managing the shader programs
angular.module('quimbi').service 'shader', (Program, settings, C) ->
	# shader to compute the euclidean distance
	euclDist = new Program.EuclDist()
	# shader to compute the angle distance
	angleDist = new Program.AngleDist()
	# shader to do direct rendering of a single channel
	renderChannel = new Program.RenderChannel()
	# shader to render the mean image of all channels in selected ranges
	renderMeanRanges = new Program.RenderMeanRanges()
	# shader to update the rgb texture for multiple selections
	rgbSelection = new Program.RGBSelection()
	# shader to normalizes the rgb intensities to fill the whole [0, 1] interval
	colorLens = new Program.ColorLens()
	# shader to apply color maps to the rgb texture
	colorMap = new Program.ColorMap()
	# shader to convert LCh colors to RGB
	lchToRgb = new Program.LchToRgb()
	# shader to render an image to the draw buffer
	drawImage = new Program.DrawImage()
	# shader to render positions as dots (from invisible to space filling) to the draw buffer
	spaceFillDisplay = new Program.SpaceFillDisplay()
	# shader to retrieve the mass intensities of a selected position
	selectionInfo = new Program.SelectionInfo()

	# creates all shader programs and adds them to glmvilib
	@createPrograms = ->
		glmvilib.addProgram euclDist
		glmvilib.addProgram angleDist
		glmvilib.addProgram renderChannel
		glmvilib.addProgram renderMeanRanges
		glmvilib.addProgram rgbSelection
		glmvilib.addProgram colorLens
		glmvilib.addProgram colorMap
		glmvilib.addProgram lchToRgb
		glmvilib.addProgram drawImage
		glmvilib.addProgram spaceFillDisplay
		glmvilib.addProgram selectionInfo
		return

	# returns all currently active shaders for a full render() or renderLoop() call
	@getActive = ->
		active = []
		switch settings.displayMode
			when C.DISPLAY_MODE.MEAN then active.push renderMeanRanges.id
			when C.DISPLAY_MODE.DIRECT then active.push renderChannel.id
			else switch settings.distMethod
				when C.DISTANCE_METHOD.ANGLE then active.push angleDist.id
				when C.DISTANCE_METHOD.EUCL then active.push euclDist.id
		active.push rgbSelection.id
		active.push colorLens.id
		active.push colorMap.id
		active.push lchToRgb.id
		if settings.useBlending
			active.push drawImage.id
		active.push spaceFillDisplay.id
		active

	# returns the shader id for rendering to the canvas
	@getFinal = ->
		final = []
		final.push colorMap.id
		final.push lchToRgb.id
		final.push drawImage.id if settings.useBlending
		final.push spaceFillDisplay.id
		final

	# sets the color mask for updating the rgb texture
	@setActiveColorMask = (mask) ->
		if mask instanceof Array and mask.length is 3
			rgbSelection.updateColorMask mask

	# sets the color mask for reading out the rgb texture
	@setPassiveColorMask = (mask) ->
		if mask instanceof Array and mask.length is 3
			colorMap.updateColorMask mask

	@updateChannelMask = (mask, activeChannels) ->
		angleDist.updateChannelMask mask, activeChannels
		euclDist.updateChannelMask mask, activeChannels
		renderMeanRanges.updateChannelMask mask, activeChannels

	@updateRegionMask = (mask) ->
		angleDist.updateRegionMask mask
		euclDist.updateRegionMask mask
		renderMeanRanges.updateRegionMask mask
		renderChannel.updateRegionMask mask

	@updateDirectChannel = (channel) ->
		renderChannel.updateChannel channel

	@updateColorMaps = colorMap.updateColorMaps

	return
