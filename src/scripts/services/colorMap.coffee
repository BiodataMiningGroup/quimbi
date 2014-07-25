# service loading, caching and providing color maps
angular.module('quimbi').service 'colorMap', ($http, msg, MSG) ->

	cache = {}

	# names of the default color maps of Quimbi, that should be loaded and
	# cached at startup
	defaultColorMaps = [
		'red'
		'green'
		'yellow'
		'blue'
		'fire'
	]

	# parses the given input file and fills the input service
	parse = (rawInput) ->
		output = []
		colors = rawInput.split "\n"

		unless colors.length = 256
			throw new Error "#{MSG.INVALID_INPUT_FORMAT} CSV doesn't contain 256 color values."

		colors = colors.map (value) -> value.split ","

		for color, i in colors
			unless color.length is 3
				throw new Error "#{MSG.INVALID_INPUT_FORMAT} Color doesn't have 3 values at line #{i+1}."

		tmp = 0
		for color in colors
			for i in [0..2]
				tmp = parseInt color[i]
				unless 0 <= tmp <= 255
					throw new Error "#{MSG.INVALID_INPUT_FORMAT} Invalid value '#{tmp}'."
				output.push tmp

		new Uint8Array output

	load = (colorMapName) ->
		promise = $http.get "color-maps/#{colorMapName}.csv"
		promise.success (data, status) ->
			try
				cache[colorMapName] = parse data
			catch e
				msg.error "#{MSG.ERROR_READING_COLOR_MAP} (#{colorMapName}). #{e.message}"
		promise.error (data, status) ->
			msg.error "#{MSG.ERROR_READING_COLOR_MAP} (#{colorMapName}). #{MSG.STATUS_CODE} #{status}"

	@get = (colorMapName) -> cache[colorMapName]

	# adds a color map of a specific name to the cache
	@add = (colorMapName, colorMap) -> cache[colorMapName] = parse colorMap

	# adds the color maps with the given names to the cache
	@cache = (colorMapNames) ->
		for colorMapName in colorMapNames when colorMapName not of cache
			load colorMapName
			
	@cacheDefaults = => @cache defaultColorMaps

	# returns the names of all currently cached color maps
	@getAvailableColorMaps = -> colorMap for colorMap of cache

	return