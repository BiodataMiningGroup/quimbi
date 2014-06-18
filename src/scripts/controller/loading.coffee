# controller for the loading route. manages downloading of the dataset images and
# setting up of glmvilib.
angular.module('quimbi').controller 'loadingCtrl', ($scope, $timeout, state, canvas, input, shader, C, MSG) ->

	# number of files loaded in parallel
	PARALLEL = 10

	# set original size of the canvas (needed for scaling it)
	canvas.setOrigSize input.width, input.height

	# data to display for the user
	$scope.data =
		message: MSG.DOWNLOADING_DATA
		progress: 0

	# information about the downloading process
	loading =
		finished: 0
		topIndex: 0
		# number of image files to load. /4 because 4 channels are merged to 1 rgba image
		goal: Math.ceil input.channels / 4
		# catch case of fewer images than are downloaded in parallel
		parallel: -> Math.min @goal, PARALLEL

	# initialize glmvilib
	try
		glmvilib.init canvas.element[0],
			width: input.dataWidth
			height: input.dataHeight
			channels: input.channels
			# 1 unit for the channel mask in the distance computing shaders
			# 1 unit for the region mask in the distance computing shaders
			reservedUnits: 2
		shader.createPrograms()
	catch e
		$scope.$emit 'message::error', "#{MSG.SETUP_WEBGL_FAILED} #{e.message}"
		glmvilib.finish()
		$scope.$apply -> state.to C.STATE.INIT

	# callback for image onload event
	load = ->
		loading.finished++
		progress = Math.round loading.finished / loading.goal * 100
		$scope.$apply ->
			$scope.data.progress = progress
			$scope.data.message = "#{MSG.DOWNLOADING_DATA} #{progress}%"
		# start loading of the next image
		loadImage()

	# callback for image error event
	error = ->
		$scope.$emit 'message::error', "#{MSG.LOAD_IMAGE_FAILED} (#{@src})."
		glmvilib.finish()
		# reset to init route
		$scope.$apply -> state.to C.STATE.INIT

	# called when everything is downloaded
	finish = ->
		glmvilib.storeTiles input.images
		state.to C.STATE.DISPLAY

	loadImage = ->
		# loading is finished
		if loading.finished is loading.goal
			try
				$scope.data.message = MSG.UNPACKING_DATA
				# do a timeout so the message is displayed in the UI
				$timeout finish, 10, true
			catch e
				$scope.$emit 'message::error', "#{MSG:UNPACKING_DATA_FAILED} #{e.message}"
				glmvilib.finish()
				$scope.$apply -> state.to C.STATE.INIT

		# load the next image
		else if loading.topIndex < loading.goal
			src = input.files[loading.topIndex]
			image = input.images[loading.topIndex] = new Image()

			image.onload = load
			image.onerror = error
			image.src = input.base + src + input.format
			loading.topIndex++

	# # TODO callback for image onload event
	# # overlayLoaded = ->
	# #	console.log input.overlayImage

	# # callback for image error event
	# # don't fail if the overlay is missing
	# overlayError = ->
	# 	$scope.$emit 'message::error', "Failed to load overlay image: #{@src}."

	# # load overlay image
	# overlayImage = new Image()
	# # TODO overlayImage.onload = overlayLoaded
	# overlayImage.onerror = overlayError
	# overlayImage.src = input.overlayImage
	# input.overlayImage = overlayImage

	# kick off loading
	pack = loading.parallel()
	loadImage() while pack--
	return
