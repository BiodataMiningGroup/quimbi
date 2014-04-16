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
	# shader to apply a color maps to the rgb texture
	colorMapDisplay = new Program.ColorMapDisplay()
	# shader to retrieve the mass intensities of a selected position
	selectionInfo = new Program.SelectionInfo()

	finalShaderID = colorMapDisplay.id

	# creates all shader programs and adds them to glmvilib
	@createPrograms = ->
		glmvilib.addProgram euclDist
		glmvilib.addProgram angleDist
		glmvilib.addProgram renderChannel
		glmvilib.addProgram rgbSelection
		glmvilib.addProgram colorMapDisplay
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
		active.push finalShaderID
		active

	# returns the final shader for rendering to the canvas
	@getFinal = -> finalShaderID

	# sets the color mask for updating the rgb texture
	@setActiveColorMask = (mask) ->
		if mask instanceof Array and mask.length is 3
			rgbSelection.updateColorMask mask

	# sets the color mask for reading out the rgb texture
	@setPassiveColorMask = (mask) ->
		if mask instanceof Array and mask.length is 3
			colorMapDisplay.updateColorMask mask

	@updateChannelMask = (mask, activeChannels) ->
		angleDist.updateChannelMask mask, activeChannels
		euclDist.updateChannelMask mask, activeChannels
		renderChannel.updateChannelMask mask, activeChannels

	@updateRegionMask = (mask) ->
		angleDist.updateRegionMask mask
		euclDist.updateRegionMask mask
		renderChannel.updateRegionMask mask

	@updateColorMaps = colorMapDisplay.updateColorMaps
	
	return
