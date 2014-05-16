# manages all existing markers and provides functions to manipulate them
angular.module('quimbi').service 'markers', (Marker, settings) ->

	activeMarkerIndex = -1

	# array of all existing markers
	list = [
		new Marker 'similarity'
		new Marker 'similarity'
		new Marker 'similarity'
	]

	# single marker for the mean display mode
	meanMarkerList = [new Marker 'mean']

	# returns the list of all currently existing markers
	@getListAll = ->
		if settings.displayMode is 'mean' then meanMarkerList
		else list

	@getList = => marker for marker in @getListAll() when marker.isOn()

	# returns the selection data of all currently existing markers
	@getSelectionData = =>
		output = []
		for marker in @getList() when marker.isSet()
			output.push marker.getSelectionData()
		output

	# returns the number of maximal allowed markers
	# @getMaxNumber = -> if settings.displayMode is 'mean' then 1 else 3

	# adds a new marker and activates it, if a new one is allowed
	# @add = -> if list.length < @getMaxNumber()
	# 	# assign a colorMaskIndex to the ner marker
	# 	list.push new Marker 'similarity'
	# 	@activate list.length - 1

	# switches off the marker at the given index
	@switchOff = (index) => if @getListAll()[index]
		@getListAll()[index].switchOff()
		@deactivate() if activeMarkerIndex is index

	# removes a marker at a given index of the marker list
	# @remove = (index) -> if 0 <= index < list.length
	# 	list[index].destruct()
	# 	list.splice index, 1
	# 	activeMarkerIndex = -1 if activeMarkerIndex is index
	# 	activeMarkerIndex-- if index < activeMarkerIndex

	# sets the marker at the given index as active
	@switchOn = (index) => 
		marker = @getListAll()[index]
		if marker
			# call this first in case of activeMarkerIndex==index
			@switchOff activeMarkerIndex
			marker.switchOn()
			marker.unset()
			activeMarkerIndex = index

	# pins the active marker to the given position and sets it as inactive
	@setAt = (position) => if @hasActive()
		@getListAll()[activeMarkerIndex].setPosition position
		activeMarkerIndex = -1

	@getActiveIndex = -> activeMarkerIndex

	@hasActive = -> activeMarkerIndex isnt -1

	@deactivate = -> activeMarkerIndex = -1

	return
