# service for storing and providing the dataset input
angular.module('quimbi').service 'input', ->
	# base url to the image files
	@base = ''

	# dataset name
	@id = ''

	# image file format/extension
	@format = ''

	# image height
	@height = 0

	# image width
	@width = 0

	# number of overall channels of the image
	@channels = 0

	# information about the preprocessing process
	@preprocessing = null

	# filenames of the image files
	@files = null

	# html image objects
	@images = null

	# maximal occurring euclidean distance in this dataset
	@maxEuclDist = 0

	# applied euclidean distance normalization method
	@euclDistNormMethod = 'maximal possible distance'

	# maximal occurring angle distance in this dataset
	@maxAngleDist = Math.PI / 2

	# applied angle distance normalization method
	@angleDistNormMethod = 'maximal possible distance'

	# returns whether the dataset appears to be valid
	@valid = => @files instanceof Array && typeof @format is 'string' && @format.length > 0 && @height > 0 && @width > 0 && @channels > 0

	return