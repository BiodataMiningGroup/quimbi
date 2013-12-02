# service for reading the dataset file format.
angular.module('quimbi').service 'inputParser', ->
	Input = ->
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
		# number of overall channels of the image
		channels: 0
		# information about the preprocessing process
		preprocessing: null
		# filenames of the image files
		files: null
		# html image objects
		images: null
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

	# filters out invalid filenames (e.g. empty line at the end of the file)
	filesFilter = (item) -> item && typeof item is 'string' && item.trim() isnt ''

	# parses the given input file and returns a new input object
	@parse = (rawInput) ->
		input = new Input()
		firstLine = rawInput.indexOf '\n'
		secondLine = rawInput.indexOf '\n', firstLine + 1

		header = rawInput.substring(0, firstLine).split ','
		input.id = header[0]
		input.base = header[1]
		input.format = header[2]
		input.channels = parseInt header[3]
		input.width = parseInt header[4]
		input.height = parseInt header[5]
		if header[6]
			input.maxEuclDist = parseFloat header[6]
			input.euclDistNormMethod = 'maximal occurring distance'
		else
			# max. theoretical distance
			input.maxEuclDist = Math.sqrt(input.channels) * 255

		input.preprocessing = rawInput.substring(firstLine + 1, secondLine).split ','
		input.files = rawInput.substring(secondLine + 1).split('\n').filter filesFilter
		# SIMULATE MULTIPLE IMAGES
		input.files = [input.files]
		input.images = [new Array(input.files.length)]

		unless input.valid()
			throw
				name: 'InvalidFormatException'
				message: 'Invalid input format.'
			return null

		input

	return