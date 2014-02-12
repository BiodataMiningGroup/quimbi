# service for reading a color map CSV file
angular.module('quimbi').service 'colorMapParser', ->

	# parses the given input file and fills the input service
	@parse = (rawInput) ->
		ret = []
		colors = rawInput.split "\n"

		unless colors.length = 256
			throw
				name: 'InvalidFormatException'
				message: 'Invalid input format. CSV doesn\'t contain 256 color values.'

		colors = colors.map (value) -> value.split ","

		for color, i in colors
			unless color.length is 3
				throw
					name: 'InvalidFormatException'
					message: "Invalid input format. Color doesn\'t have 3 values at line #{i+1}."

		for color in colors
			ret.push parseInt color[0]
			ret.push parseInt color[1]
			ret.push parseInt color[2]

		new Uint8Array ret

	return