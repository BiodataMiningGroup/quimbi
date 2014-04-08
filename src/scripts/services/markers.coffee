# manages all existing markers and provides functions to manipulate them
angular.module('quimbi').service 'markers', (Marker) ->

	activeMarkerIndex = -1

	lastChangedMarkerIndex = -1

	# array of all existing markers
	@list = []

	# array of the SelectionData of all existing markers
	@selectionData = []

	Object.defineProperty @, 'maxNumber', value: 3

	@add = -> if @list.length < @maxNumber
		# assign a colorMaskIndex to the ner marker
		@list.push new Marker()
		@activate @list.length - 1

	@remove = (index) -> if 0 <= index < @list.length
		@list[index].destruct()
		@list.splice index, 1
		@selectionData.splice index, 1
		activeMarkerIndex = -1 if activeMarkerIndex is index
		lastChangedMarkerIndex = @list.length - 1 if lastChangedMarkerIndex is index

	@activate = (index) -> if index < @list.length
		activeMarkerIndex = index

	@set = (position) -> unless activeMarkerIndex is -1
		@selectionData[activeMarkerIndex] =
			@list[activeMarkerIndex].setPosition position
		lastChangedMarkerIndex = activeMarkerIndex
		activeMarkerIndex = -1

	@getActiveIndex = -> activeMarkerIndex

	@hasActive = -> activeMarkerIndex isnt -1

	@getLastChangedIndex = -> lastChangedMarkerIndex

	return
