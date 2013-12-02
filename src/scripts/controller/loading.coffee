# controller for the loading route. manages downloading of the dataset images and
# setting up of mvi.
angular.module('quimbi').controller 'loadingCtrl', ($scope, state, canvas) ->
	# number of files loaded in parallel
	PARALLEL = 10

	# information about the dataset
	input = $scope.input
	# set original size of the canvas (needed for scaling it)
	canvas.setOrigSize input.width, input.height

	# data to display for the user
	$scope.data = 
		message: 'Downloading images.'
		progress: 0

	# information about the downloading process
	loading =
		finished: 0
		topIndex: 0
		# number of image files to load. /4 because 4 channels are merged to 1 rgba image
		goal: Math.ceil input.images.length * input.channels / 4
		# catch case of fewer images than are downloaded in parallel
		parallel: -> if @goal < PARALLEL then @goal else PARALLEL

	# mvi callback when everything is set up
	displayCall = ->
		$scope.$emit 'message::success', 'Sucessfully loaded.'
		state.to 'display'
		$scope.$apply()

	# mvi callback for the loading progress
	progressCall = (percent) ->
		# this processing is the second half of the overall loading progress
		$scope.data.progress = 50 + Math.round(percent * 100) / 2
		$scope.data.message = "Processing textures: #{Math.round percent * 100}%."
		$scope.$apply()

	# callback for image onload event
	load = ->
		loading.finished++
		progress = Math.round loading.finished / loading.goal * 100
		# the image loading is the first half of the overall loading progress
		# so progress = progress / 2
		$scope.data.progress = progress / 2
		$scope.data.message = "Downloading images: #{progress}%."
		$scope.$apply()
		# start loading of the next image
		loadImage()

	# callback for image error event
	error = ->
		$scope.$emit 'message::error', "Failed to load image: #{@src}."
		# reset to init route
		state.to 'init'
		$scope.$apply()

	loadImage = ->
		# loading is finished
		if loading.finished is loading.goal
			mvi.setUp canvas.element[0], input, displayCall, progressCall
		# load the next image
		else if loading.topIndex < loading.goal
			# index of the channel of this image
			index = loading.topIndex % input.channels
			# index of this image
			imageIndex = Math.floor loading.topIndex / input.channels
			loading.topIndex++
			src = input.files[imageIndex][index]
			image = input.images[imageIndex][index] = new Image()

			image.onload = load
			image.onerror = error
			image.src = input.base + src + input.format

	# kick off loading
	pack = loading.parallel()
	while pack-- then loadImage()
	return