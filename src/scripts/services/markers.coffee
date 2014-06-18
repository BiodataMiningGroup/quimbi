# manages all existing markers and provides functions to manipulate them
angular.module('quimbi').service 'markers', (Marker, settings) ->

	activeMarkerIndex = -1

	# array of all existing markers
	list = [
		new Marker Marker.TYPE_SINGLE
		new Marker Marker.TYPE_MULTI
		new Marker Marker.TYPE_MULTI
		new Marker Marker.TYPE_MULTI
	]

	# single marker for the mean display mode
	meanMarkerList = [
		new Marker Marker.TYPE_MEAN
	]

	# single marker for the direct display mode
	directMarkerList = [
		new Marker Marker.TYPE_DIRECT
	]

	# returns the list of all currently existing markers
	@getListAll = -> switch settings.displayMode
		when 'mean' then meanMarkerList
		when 'direct' then directMarkerList
		else list

	@getList = => marker for marker in @getListAll() when marker.isOn()

	# returns the selection data of all currently existing markers
	@getSelectionData = =>
		marker.getSelectionData() for marker in @getList() when marker.isSet()

	# switches off the marker at the given index
	@switchOff = (index) => if marker = @getListAll()[index]
		marker.switchOff()
		@deactivate() if activeMarkerIndex is index

	# sets the marker at the given index as active
	@switchOn = (index) => if marker = @getListAll()[index]
		# if the single marker gets switched on, switch off all multi markers
		# and vice versa
		m.switchOff() for m in @getList() when m.getType() isnt marker.getType()
		# call this first in case of activeMarkerIndex==index
		@switchOff activeMarkerIndex
		marker.unset()
		marker.switchOn()
		activeMarkerIndex = index

	# pins the active marker to the given position and sets it as inactive
	@setAt = (position) => if @hasActive()
		@getListAll()[activeMarkerIndex].setPosition position
		activeMarkerIndex = -1

	@getActiveIndex = -> activeMarkerIndex

	@hasActive = -> activeMarkerIndex isnt -1

	@deactivate = -> activeMarkerIndex = -1

	return
