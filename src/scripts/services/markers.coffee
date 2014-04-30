# manages all existing markers and provides functions to manipulate them
angular.module('quimbi').service 'markers', (Marker, settings) ->

	activeMarkerIndex = -1

	# array of all existing markers
	list = []

	# single marker for the mean display mode
	meanMarkerList = [new Marker 'mean']

	# returns the list of all currently existing markers
	@getList = ->
		if settings.displayMode is 'distances' then list
		else meanMarkerList

	# returns the selection data of all currently existing markers
	@getSelectionData = =>
		output = []
		for marker in @getList() when marker.isSet()
			output.push marker.getSelectionData()
		output

	# returns the number of maximal allowed markers
	@getMaxNumber = -> if settings.displayMode is 'distances' then 3 else 1

	# adds a new marker and activates it, if a new one is allowed
	@add = -> if list.length < @getMaxNumber()
		# assign a colorMaskIndex to the ner marker
		list.push new Marker 'distances'
		@activate list.length - 1

	# removes a marker at a given index of the marker list
	@remove = (index) -> if 0 <= index < list.length
		list[index].destruct()
		list.splice index, 1
		activeMarkerIndex = -1 if activeMarkerIndex is index
		activeMarkerIndex-- if index < activeMarkerIndex

	# sets the marker at the given index as active
	@activate = (index) => if index < @getList().length
		activeMarkerIndex = index

	# pins the active marker to the given position and sets it as inactive
	@setAt = (position) => if @hasActive()
		@getList()[activeMarkerIndex].setPosition position
		activeMarkerIndex = -1

	@getActiveIndex = -> activeMarkerIndex

	@hasActive = -> activeMarkerIndex isnt -1

	return
