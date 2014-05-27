# service for managing the shader programs
angular.module('quimbi').service 'shader', (Program, settings) ->
	# shader to compute the euclidean distance
	euclDist = new Program.EuclDist()
	# shader to compute the angle distance
	angleDist = new Program.AngleDist()
	# shader to do direct rendering of a single channel
	renderChannel = new Program.RenderChannel()
	# shader to update the rgb texture for multiple selections
	rgbSelection = new Program.RGBSelection()
	# shader to apply color maps to the rgb texture
	colorMap = new Program.ColorMap()
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
		glmvilib.addProgram rgbSelection
		glmvilib.addProgram colorMap
		glmvilib.addProgram drawImage
		glmvilib.addProgram spaceFillDisplay
		glmvilib.addProgram selectionInfo
		return

	# returns all currently active shaders for a full render() or renderLoop() call
	@getActive = ->
		active = []
		switch settings.displayMode
			when 'mean' then active.push renderChannel.id
			else switch settings.distMethod
				when 'angle' then active.push angleDist.id
				when 'eucl' then active.push euclDist.id
		active.push rgbSelection.id
		active.push colorMap.id
		if settings.useBlending
			active.push drawImage.id
		active.push spaceFillDisplay.id
		active

	# returns the shader id for rendering to the rgb intensity texture
	@getIntensity = -> rgbSelection.id

	# returns the shader id for rendering to the color map
	@getColor = -> colorMap.id

	# returns the shader id for rendering to the canvas
	@getFinal = ->
		if settings.useBlending
			[drawImage.id, spaceFillDisplay.id]
		else
			spaceFillDisplay.id

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
		renderChannel.updateChannelMask mask, activeChannels

	@updateRegionMask = (mask) ->
		angleDist.updateRegionMask mask
		euclDist.updateRegionMask mask
		renderChannel.updateRegionMask mask

	@updateColorMaps = colorMap.updateColorMaps

	return
