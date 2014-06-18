# creates a new Marker object. A marker represets a selected point on the map.
angular.module('quimbi').factory 'Marker', (input, mouse, SelectionData, ColorGroupObject, colorGroups) ->

	class Marker extends ColorGroupObject

		@colorGroupIndex: 0

		@TYPE_MULTI: 'multi'
		@TYPE_SINGLE: 'single'
		@TYPE_MEAN: 'mean'
		@TYPE_DIRECT: 'direct'

		constructor: (@_type) ->
			switch @_type
				when Marker.TYPE_MULTI
					super colorGroups.get 1 + Marker.colorGroupIndex++
				else
					super colorGroups.get 0

			@_textureDimension = input.getChannelTextureDimension()

			@_position =
				x: 0.5
				y: 0.5
				lat: 0
				lng: 0

			# spectrogram and histogram of the position of this marker
			@_selectionData = new SelectionData()

			@_isSet = no

			@_isOn = no

		# releases the assigned color group
		destruct: ->if @_type is Marker.TYPE_MULTI then Marker.colorGroupIndex--

		_updateSelection: ->
			angular.extend mouse.position, @_position
			glmvilib.render 'selection-info'
			# update spectrogram
			glmvilib.getPixels 0, 0, @_textureDimension, @_textureDimension, @_selectionData.spectrogram

			# update histogram
			for intensity in [0...@_selectionData.histogram.length]
				@_selectionData.histogram[intensity] = 0
			for channel in [0...input.channels]
				@_selectionData.histogram[@_selectionData.spectrogram[channel]]++

			@_selectionData

		getSelectionData: ->
			color: @getColor()
			data: @_selectionData

		getPosition: -> angular.copy @_position

		# returns the updated selectionData associated with the color
		setPosition: (position) ->
			@_isSet = yes
			@_position.x = position.x
			@_position.y = position.y
			@_position.lat = position.lat
			@_position.lng = position.lng
			# AFTER setting the new position
			@_updateSelection()
			position

		getType: -> @_type

		isSet: -> @_isOn and @_isSet

		unset: -> @_isSet = no

		isOn: -> @_isOn

		switchOn: -> @_isOn = yes

		switchOff: -> @_isOn = no
