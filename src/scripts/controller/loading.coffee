# controller for the loading route. manages downloading of the dataset images and
# setting up of glmvilib.
angular.module('quimbi').controller 'loadingCtrl', ($scope, state, canvas, input, TileProgram) ->
	# number of files loaded in parallel
	PARALLEL = 10

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
		goal: Math.ceil input.channels / 4
		# catch case of fewer images than are downloaded in parallel
		parallel: -> if @goal < PARALLEL then @goal else PARALLEL

	# initialize glmvilib
	glmvilib.init canvas.element[0], input
	program = new TileProgram()
	glmvilib.addProgram program.id, program.vertexShader, program.fragmentShader, program.constructor
	glmvilib.addProgramCallback program.id, program.callback

	# TODO initialize all shader programs

	# callback for image onload event
	load = ->
		loading.finished++
		progress = Math.round loading.finished / loading.goal * 100
		$scope.$apply ->
			$scope.data.progress = progress
			$scope.data.message = "Downloading images: #{progress}%."
		# start loading of the next image
		loadImage()

	# callback for image error event
	error = ->
		$scope.$emit 'message::error', "Failed to load image: #{@src}."
		# reset to init route
		$scope.$apply -> state.to 'init'

	loadImage = ->
		# loading is finished
		if loading.finished is loading.goal
			glmvilib.storeTiles input.images
			$scope.$apply -> state.to 'display'
		# load the next image
		else if loading.topIndex < loading.goal
			src = input.files[loading.topIndex]
			image = input.images[loading.topIndex] = new Image()

			image.onload = load
			image.onerror = error
			image.src = input.base + src + input.format
			loading.topIndex++

	# kick off loading
	pack = loading.parallel()
	while pack-- then loadImage()
	return