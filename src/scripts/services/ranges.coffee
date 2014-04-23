# manages all existing ranges and provides functions to manipulate them
angular.module('quimbi').service 'ranges', ->

	@list = []

	@remove = (index) => @list.splice index, 1

	@hasActive = ->
		for range in @list when range.active
			return yes
		no
		
	@byGroup = =>
		output = {}

		for range in @list
			group = range.getGroup()
			if output[group] instanceof Array
				output[group].push range
			else
				output[group] = [range]
				
		output

	@currentGroups = =>
		output = []
		for range in @list
			group = range.getGroup()
			output.push group unless group in output
		output

	return
