# service for storing information about current selections
angular.module('quimbi').service 'selection', (input, mouse, $document) ->
	# calculate the dimension of the framebuffer texture. for each tile
	# of the dataset there should be one pixel in this texture.
	@textureDimension = Math.ceil Math.sqrt Math.ceil input.channels / 4

	intensities = new Uint8Array @textureDimension * @textureDimension * 4

	# array that stores the array of channel names in the index of their intensities
	@intensities = []
	count = 256
	while count-- then @intensities.push []

	clearIntensities = =>
		element.length = 0 for element in @intensities
		return

	mapIntensities = =>
		channel = input.channels
		while channel--
			# TODO fetch real channel names
			@intensities[intensities[channel]].push "channel #{channel}"
		@intensities

	@fingerprint = $document[0].createElement 'canvas'
	@fingerprint.height = @fingerprint.width = @textureDimension
	fingerprintCtx = @fingerprint.getContext '2d'
	fingerprintData = fingerprintCtx.createImageData @textureDimension, @textureDimension

	@make = (x, y) =>
		glmvilib.setViewport 0, 0, @textureDimension, @textureDimension
		mouse.position.x = x
		mouse.position.y = y
		glmvilib.render 'selection-info'
		glmvilib.getPixels 0, 0, @textureDimension, @textureDimension, intensities
		glmvilib.setViewport 0, 0, input.width, input.height

		fingerprintData.data[index] = value for value, index in intensities
		fingerprintCtx.putImageData fingerprintData, 0, 0
		clearIntensities()
		mapIntensities()
	return