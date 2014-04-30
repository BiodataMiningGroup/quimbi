# manages all existing ranges and provides functions to manipulate them
angular.module('quimbi').service 'ranges', ->

	# list of all currently existing ranges
	@list = []

	# removes a range at the given index of the list
	@remove = (index) => @list.splice index, 1

	# is there an active range in the list?
	@hasActive = ->
		for range in @list when range.active
			return yes
		no
	
	# returns all existing markers ordered by their group
	@byGroup = =>
		output = {}

		for range in @list
			group = range.getGroup()
			if output[group] instanceof Array
				output[group].push range
			else
				output[group] = [range]
				
		output

	return
