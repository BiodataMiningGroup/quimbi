# service for getting the spectrogram of a selection
angular.module('quimbi').service 'selection', (input, mouse, $document, SelectionData) ->
	# calculate the dimension of the framebuffer texture. for each tile
	# of the dataset there should be one pixel in this texture.
	@textureDimension = Math.ceil Math.sqrt Math.ceil input.channels / 4

	intensities = new Uint8Array @textureDimension * @textureDimension * 4

	# @fingerprint = $document[0].createElement 'canvas'
	# @fingerprint.height = @fingerprint.width = @textureDimension
	# fingerprintCtx = @fingerprint.getContext '2d'
	# fingerprintData = fingerprintCtx.createImageData @textureDimension, @textureDimension

	@make = (position) =>
		glmvilib.setViewport 0, 0, @textureDimension, @textureDimension
		mouse.position.x = position.x
		mouse.position.y = position.y
		glmvilib.render 'selection-info'
		glmvilib.getPixels 0, 0, @textureDimension, @textureDimension, intensities
		glmvilib.setViewport 0, 0, input.width, input.height

		# fingerprintData.data[index] = value for value, index in intensities
		# fingerprintCtx.putImageData fingerprintData, 0, 0

		new SelectionData intensities
	return