# Service for sharing properties between the controllers. Manages parsing of
# different file formats.

angular.module('quimbi').service 'inputParser', ->
	Input = ->
		base: ''
		id: ''
		format: ''
		height: 0
		width: 0
		channels: 0
		preprocessing: null
		files: null
		images: null
		maxEuclDist: 0
		euclDistNormMethod: 'maximal possible distance'
		maxAngleDist: Math.PI / 2
		angleDistNormMethod: 'maximal possible distance'
		valid: -> @files instanceof Array && typeof @format is 'string' && @format.length > 0 && @height > 0 && @width > 0 && @channels > 0

	filesFilter = (item) -> item && typeof item is 'string' && item.trim() isnt ''

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