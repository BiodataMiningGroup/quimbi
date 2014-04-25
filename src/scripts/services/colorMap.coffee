# service loading, caching and providing color maps
angular.module('quimbi').service 'colorMap', ($http, msg) ->

	cache = {}

	defaultColorMaps = [
		'red'
		'green'
		'blue'
		'cyan'
		'magenta'
		'yellow'
		'phase'
		'fire'
	]

	# parses the given input file and fills the input service
	parse = (rawInput) ->
		output = []
		colors = rawInput.split "\n"

		unless colors.length = 256
			throw new Error "Invalid input format. CSV doesn't contain 256 color values."

		colors = colors.map (value) -> value.split ","

		for color, i in colors
			unless color.length is 3
				throw new Error "Invalid input format. Color doesn't have 3 values at line #{i+1}."

		for color in colors
			output.push parseInt color[0]
			output.push parseInt color[1]
			output.push parseInt color[2]

		new Uint8Array output

	load = (colorMapName) ->
		promise = $http.get "color-maps/#{colorMapName}.csv"
		promise.success (data, status) ->
			try
				cache[colorMapName] = parse data
			catch e
				msg.error "Error while reading color map '#{colorMapName}'. #{e.message}"
		promise.error (data, status) ->
			msg.error "Color map '#{colorMapName}' couldn't be loaded! Status code #{status}"

	@get = (colorMapName) -> cache[colorMapName]

	# adds a color map of a specific name to the cache
	@add = (colorMapName, colorMap) -> cache[colorMapName] = parse colorMap

	# adds the color maps with the given names to the cache
	@cache = (colorMapNames) ->
		for colorMapName in colorMapNames when colorMapName not of cache
			load colorMapName

	@cacheDefaults = => @cache defaultColorMaps

	@getAvailableColorMaps = -> colorMap for colorMap of cache

	return