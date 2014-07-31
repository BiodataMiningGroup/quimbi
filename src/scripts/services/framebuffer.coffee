# service to provide the content of different webgl framebuffers
angular.module('quimbi').service 'framebuffer', (input, mouse) ->

	intensities = new Uint8Array input.dataWidth * input.dataHeight * 4

	mouseIntensities = [0, 0, 0, 0]

	colors = new Uint8Array input.dataWidth * input.dataHeight * 4

	mouseColors = [0, 0, 0, 0]

	@updateIntensities = ->
		glmvilib.getPixels 0, 0, input.dataWidth, input.dataHeight, intensities

	@updateColors = ->
		glmvilib.getPixels 0, 0, input.dataWidth, input.dataHeight, colors

	@getIntensities = -> intensities

	@getMouseIntensities = ->
		position = (mouse.position.dataY * input.dataWidth + mouse.position.dataX) * 4
		for index in [0...mouseIntensities.length]
			mouseIntensities[index] = intensities[position + index]
		mouseIntensities

	@getColors = -> colors

	@getMouseColors = ->
		position = (mouse.position.dataY * input.dataWidth + mouse.position.dataX) * 4
		for index in [0...mouseColors.length]
			mouseColors[index] = colors[position + index]
		mouseColors

	return