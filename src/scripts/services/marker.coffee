angular.module('quimbi').service 'marker', (Marker) ->

	activeMarkerIndex = -1

	lastChangedMarkerIndex = -1

	# array of all existing markers
	@markers = []

	# array of the SelectionData of all existing markers
	@selectionData = []

	Object.defineProperty @, 'maxMarkers', value: 3

	@add = -> if @markers.length < @maxMarkers
		@markers.push new Marker()
		@activate @markers.length - 1

	@remove = (index) ->
		@markers.splice index, 1
		@selectionData.splice index, 1
		activeMarkerIndex = -1 if activeMarkerIndex is index
		lastChangedMarkerIndex = @markers.length - 1 if lastChangedMarkerIndex is index

	@activate = (index) -> if index < @markers.length
		activeMarkerIndex = index

	@set = (position) -> unless activeMarkerIndex is -1
		@selectionData[activeMarkerIndex] =
			@markers[activeMarkerIndex].setPosition position
		lastChangedMarkerIndex = activeMarkerIndex
		activeMarkerIndex = -1

	@getActiveIndex = -> activeMarkerIndex

	@getLastChangedIndex = -> lastChangedMarkerIndex

	return
