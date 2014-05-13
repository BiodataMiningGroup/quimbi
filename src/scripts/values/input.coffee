# storing and providing the dataset input
angular.module('quimbi').value 'input',
	# base url to the image files
	base: ''

	# dataset name
	id: ''

	# image file format/extension
	format: ''

	# image height
	height: 0

	# image width
	width: 0

	# image height
	dataHeight: 0

	# image width
	dataWidth: 0

	# number of overall channels of the image
	channels: 0

	# the dimension of a quadratic texture to contain one pixel for each 4 channels
	getChannelTextureDimension: -> Math.ceil Math.sqrt Math.ceil @channels / 4

	# information about the preprocessing process
	preprocessing: null

	# filenames of the image files
	files: null

	# name of each channel in correct ordering fetched from the file names
	channelNames: null

	# html image objects
	images: null

	# url to overlay image
	overlayImage: ''

	# scale required to align overlay and data dimensions (for x and y axis)
	overlayScale:
		x: 1
		y: 1

	# shift required to align overlay and data dimensions (for x and y axis)
	overlayShift:
		x: 0
		y: 0

	# maximal occurring euclidean distance in this dataset
	maxEuclDist: 0

	# applied euclidean distance normalization method
	euclDistNormMethod: 'maximal possible distance'

	# maximal occurring angle distance in this dataset
	maxAngleDist: Math.PI / 2

	# applied angle distance normalization method
	angleDistNormMethod: 'maximal possible distance'

	# returns whether the dataset appears to be valid
	valid: -> @files instanceof Array && typeof @format is 'string' && @format.length > 0 && @height > 0 && @width > 0 && @channels > 0
