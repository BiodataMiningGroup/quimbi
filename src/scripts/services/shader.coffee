# service for managing the shader programs
angular.module('quimbi').service 'shader', (Program, settings) ->
	euclDist = new Program.EuclDist()
	angleDist = new Program.AngleDist()
	rgbSelection = new Program.RGBSelection()
	pseudocolorDisplay = new Program.PseudocolorDisplay()
	
	@createPrograms = ->
		glmvilib.addProgram euclDist.id, euclDist.vertexShader, euclDist.fragmentShader, euclDist.constructor
		glmvilib.addProgramCallback euclDist.id, euclDist.callback

		glmvilib.addProgram angleDist.id, angleDist.vertexShader, angleDist.fragmentShader, angleDist.constructor
		glmvilib.addProgramCallback angleDist.id, angleDist.callback

		glmvilib.addProgram rgbSelection.id, rgbSelection.vertexShader, rgbSelection.fragmentShader, rgbSelection.constructor
		glmvilib.addProgramCallback rgbSelection.id, rgbSelection.callback

		glmvilib.addProgram pseudocolorDisplay.id, pseudocolorDisplay.vertexShader, pseudocolorDisplay.fragmentShader, pseudocolorDisplay.constructor
		glmvilib.addProgramCallback pseudocolorDisplay.id, pseudocolorDisplay.callback
		return

	@getActive = ->
		active = []
		switch settings.distMethod
			when 'angle' then active.push angleDist.id
			when 'eucl' then active.push euclDist.id
		active.push rgbSelection.id
		active.push pseudocolorDisplay.id
		active

	@setActiveColorMask = (mask) ->
		if mask instanceof Array and mask.length is 3
			rgbSelection.colorMask = mask

	@setPassiveColorMask = (mask) ->
		if mask instanceof Array and mask.length is 3
			pseudocolorDisplay.colorMask = mask

	return