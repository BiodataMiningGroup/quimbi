# creates a new Marker object. A marker represets a selected point on the map.
angular.module('quimbi').factory 'Marker', (input, mouse, SelectionData, settings) ->

	class Marker

		# contains all unassigned color mask indices
		# a color mask index specifies the index of a [0, 0, 0] color mask array
		# that must be set to 1
		@colorMaskIndices: [0, 1, 2]

		constructor: (@_type) ->

			if @_type is 'mean'
				@_color = settings.singleSelectionSingleColor
				@_index = 0
			else
				@_index = Marker.colorMaskIndices.shift()
				@_color = settings.colorMapSingleColors[@_index]

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

		# releases the assigned color mask index
		destruct: -> if @_type is 'similarity'
			Marker.colorMaskIndices.unshift @_index

		_updateSelection: ->
			glmvilib.setViewport 0, 0, @_textureDimension, @_textureDimension
			angular.extend mouse.position, @_position
			glmvilib.render 'selection-info'
			# update spectrogram
			glmvilib.getPixels 0, 0, @_textureDimension, @_textureDimension, @_selectionData.spectrogram
			glmvilib.setViewport 0, 0, input.width, input.height

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

		getColor: -> @_color

		getIndex: -> @_index

		getType: -> @_type

		isSet: -> @_isOn and @_isSet

		unset: -> @_isSet = no

		isOn: -> @_isOn

		switchOn: -> @_isOn = yes

		switchOff: -> @_isOn = no
