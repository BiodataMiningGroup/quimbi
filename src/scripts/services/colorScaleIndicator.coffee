angular.module('quimbi').service 'colorScaleIndicator', ($timeout, mouse, shader) ->

	intensities = new Uint8Array 4

	normalizedIntensities = [0, 0, 0, 0]

	color = new Uint8Array 4

	timeoutPromise = null

	delay = 100

	getPixels = ->
		glmvilib.render shader.getIntensity()
		glmvilib.getPixels mouse.position.dataX, mouse.position.dataY, 1, 1, intensities
		glmvilib.render shader.getColor()
		glmvilib.getPixels mouse.position.dataX, mouse.position.dataY, 1, 1, color

	@update = ->
		$timeout.cancel timeoutPromise
		timeoutPromise = $timeout getPixels, delay, no

	@getIntensities = -> intensities

	@getColor = -> color

	# normalizes the color channel intensities so r+g+b=1
	@getNormalizedIntensities = ->
		sum = intensities[0] + intensities[1] + intensities[2]
		for intensity, index in intensities
			normalizedIntensities[index] = if sum is 0 then 1 / 3 else intensity / sum
		normalizedIntensities

	return
