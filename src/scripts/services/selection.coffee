# service for storing information about current selections
angular.module('quimbi').service 'selection', (input, mouse, $document, SelectionData) ->
	# calculate the dimension of the framebuffer texture. for each tile
	# of the dataset there should be one pixel in this texture.
	@textureDimension = Math.ceil Math.sqrt Math.ceil input.channels / 4

	@data = null

	intensities = new Uint8Array @textureDimension * @textureDimension * 4

	count = 256

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

		@data = new SelectionData intensities
	return