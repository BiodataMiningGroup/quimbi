# service for managing the shader programs
angular.module('quimbi').service 'shader', (Program, settings) ->
	# shader to compute the euclidean distance
	euclDist = new Program.EuclDist()
	# shader to compute the angle distance
	angleDist = new Program.AngleDist()
	# shader to update the rgb texture for multiple selections
	rgbSelection = new Program.RGBSelection()
	# shader to produce the final image from the rgb texture
	pseudocolorDisplay = new Program.PseudocolorDisplay()
	# shader to apply a color map to the R channel of the rgb texture
	colorMapDisplay = new Program.ColorMapDisplay()
	# shader to retrieve the mass intensities of a selected position
	selectionInfo = new Program.SelectionInfo()

	finalShaderID = pseudocolorDisplay.id
	
	# creates all shader programs and adds them to glmvilib
	@createPrograms = ->
		glmvilib.addProgram euclDist
		glmvilib.addProgram angleDist
		glmvilib.addProgram rgbSelection
		glmvilib.addProgram pseudocolorDisplay
		glmvilib.addProgram colorMapDisplay
		glmvilib.addProgram selectionInfo
		return

	# returns all currently active shaders for a full render() or renderLoop() call
	@getActive = ->
		active = []
		switch settings.distMethod
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
			rgbSelection.colorMask = mask

	# sets the color mask for reading out the rgb texture
	@setPassiveColorMask = (mask) ->
		if mask instanceof Array and mask.length is 3
			pseudocolorDisplay.colorMask = mask

	# link the mask that determines which channels should be considered in calculation
	# since it stays the same object, only the reference has to be passed once
	@updateChannelMask = (mask) -> angleDist.updateChannelMask mask

	# sets the final shader for rendering to the canvas
	@setFinal = (id) ->
		if id is pseudocolorDisplay.id or id is colorMapDisplay.id
			finalShaderID = id

	return