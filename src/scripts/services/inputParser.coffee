# service for reading the dataset file format.
angular.module('quimbi').service 'inputParser', (input) ->

	# filters out invalid filenames (e.g. empty line at the end of the file)
	filesFilter = (item) -> item && typeof item is 'string' && item.trim() isnt ''

	# parses the given input file and fills the input service
	@parse = (rawInput) ->
		firstLine = rawInput.indexOf '\n'
		secondLine = rawInput.indexOf '\n', firstLine + 1
		# data/OpG4dVa20120918Sc4/Optic G4d Vakuum 20120918_4_small.png,1,1,0,0
		brightfieldConfigLine = rawInput.indexOf '\n', secondLine + 1
		brightfieldConfig = rawInput.substring(secondLine + 1, brightfieldConfigLine).split ','
		input.backgroundImage = brightfieldConfig[0]
		input.overlayImage = brightfieldConfig[1]
		input.overlayScaleX = parseFloat brightfieldConfig[2]
		input.overlayScaleY = parseFloat brightfieldConfig[3]
		input.overlayShiftX = parseFloat brightfieldConfig[4]
		input.overlayShiftY = parseFloat brightfieldConfig[5]

		header = rawInput.substring(0, firstLine).split ','
		input.id = header[0]
		input.base = header[1]
		input.format = header[2]
		input.channels = parseInt header[3]
		input.width = parseInt header[4] * input.overlayScaleX # DEV
		input.height = parseInt header[5] * input.overlayScaleY # DEV
		input.dataWidth = parseInt header[4]
		input.dataHeight = parseInt header[5]
		if header[6]
			input.maxEuclDist = parseFloat header[6]
			input.euclDistNormMethod = 'maximal occurring distance'
		else
			# max. theoretical distance
			input.maxEuclDist = Math.sqrt(input.channels) * 255

		input.preprocessing = rawInput.substring(firstLine + 1, secondLine).split ','
		input.files = rawInput.substring(brightfieldConfigLine + 1).split('\n').filter filesFilter
		input.channelNames = []
		input.files.forEach (file) ->
			file.split('-').forEach (name) ->
				input.channelNames.push name

		input.images = new Array input.files.length

		unless input.valid()
			throw
				name: 'InvalidFormatException'
				message: 'Invalid input format.'
		return

	return
