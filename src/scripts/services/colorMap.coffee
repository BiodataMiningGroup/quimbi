# service loading, caching and providing color maps
angular.module('quimbi').service 'colorMap', ($http, $q, msg) ->

	cache = {}

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

	# returns the rgb color of a [0, 1] position on a color map
	@getInterpolatedColor = (colorMapName, intensity) ->
		color = [0, 0, 0]
		colorMap = cache[colorMapName]
		exactIndex = 255 * intensity
		index = Math.floor exactIndex
		interpolation = exactIndex - index
		for i in [0...3]
			color[i] = colorMap[3 * index + i] * (1 - interpolation)
			nextColor = colorMap[3 * (index + 1) + i]
			color[i] +=  nextColor * interpolation if nextColor isnt undefined
		color

	return