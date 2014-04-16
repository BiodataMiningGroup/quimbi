# service loading, caching and providing color maps
angular.module('quimbi').service 'colorMap', ($http, $q) ->

	cache = {}

	# parses the given input file and fills the input service
	parse = (rawInput) ->
		output = []
		colors = rawInput.split "\n"

		unless colors.length = 256
			throw
				name: 'InvalidFormatException'
				message: "Invalid input format. CSV doesn't contain 256 color values."

		colors = colors.map (value) -> value.split ","

		for color, i in colors
			unless color.length is 3
				throw
					name: 'InvalidFormatException'
					message: "Invalid input format. Color doesn't have 3 values at line #{i+1}."

		for color in colors
			output.push parseInt color[0]
			output.push parseInt color[1]
			output.push parseInt color[2]

		new Uint8Array output

	load = (colorMapName) -> $http.get "color-maps/#{colorMapName}.csv"

	@get = (colorMapName) ->
		deferred = $q.defer()
		if colorMapName of cache
			deferred.resolve cache[colorMapName]
		else
			deferred.resolve load(colorMapName).then (data, status) ->
				cache[colorMapName] = parse data.data
		deferred.promise

	@add = (colorMapName, colorMap) ->
		if colorMap instanceof Uint8Array and colorMap.length is 768
			cache[colorMapName] = colorMap

	return