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
	# shader to retrieve the mass intensities of a selected position
	selectionInfo = new Program.SelectionInfo()
	
	# creates all shader programs and adds them to glmvilib
	@createPrograms = ->
		glmvilib.addProgram euclDist
		glmvilib.addProgram angleDist
		glmvilib.addProgram rgbSelection
		glmvilib.addProgram pseudocolorDisplay
		glmvilib.addProgram selectionInfo
		return

	# returns all currently active shaders for a render() or renderLoop() call
	@getActive = ->
		active = []
		switch settings.distMethod
			when 'angle' then active.push angleDist.id
			when 'eucl' then active.push euclDist.id
		active.push rgbSelection.id
		active.push pseudocolorDisplay.id
		active

	# sets the color mask for updating the rgb color
	@setActiveColorMask = (mask) ->
		if mask instanceof Array and mask.length is 3
			rgbSelection.colorMask = mask

	# sets the color mask for reading out the rgb texture
	@setPassiveColorMask = (mask) ->
		if mask instanceof Array and mask.length is 3
			pseudocolorDisplay.colorMask = mask

	return