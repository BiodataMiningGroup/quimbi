# manages all existing markers and provides functions to manipulate them
angular.module('quimbi').service 'markers', (Marker, settings) ->

	activeMarkerIndex = -1

	lastChangedMarkerIndex = -1

	# array of all existing markers
	list = []

	meanMarker = new Marker 'mean'

	@getList = ->
		if settings.displayMode is 'distances'
			list
		else
			[meanMarker]

	@getSelectionData = =>
		output = []
		for marker in @getList() when marker.isSet()
			output.push marker.getSelectionData()
		output

	@getMaxNumber = ->
		if settings.displayMode is 'distances' then 3 else 1

	@add = -> if list.length < @getMaxNumber()
		# assign a colorMaskIndex to the ner marker
		list.push new Marker 'distances'
		@activate list.length - 1

	@remove = (index) -> if 0 <= index < list.length
		list[index].destruct()
		list.splice index, 1
		activeMarkerIndex = -1 if activeMarkerIndex is index
		lastChangedMarkerIndex = list.length - 1 if lastChangedMarkerIndex is index

	@activate = (index) => if index < @getList().length
		activeMarkerIndex = index

	@set = (position) => unless activeMarkerIndex is -1
		@getList()[activeMarkerIndex].setPosition position
		lastChangedMarkerIndex = activeMarkerIndex
		activeMarkerIndex = -1

	@getActiveIndex = -> activeMarkerIndex

	@hasActive = -> activeMarkerIndex isnt -1

	@getLastChangedIndex = -> lastChangedMarkerIndex

	return
