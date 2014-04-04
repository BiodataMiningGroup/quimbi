# creates a new Marker object
angular.module('quimbi').factory 'Marker', (input, mouse, SelectionData) ->

	class Marker
		
		constructor: (@_colorMaskIndex) ->

			@_textureDimension = input.getChannelTextureDimension()

			@_position =
				x: 0.5
				y: 0.5
				lat: 0
				lng: 0

			@_color = 'white'
		
			@_colorMap = []

			# spectrogram and histogram of the position of this marker
			@_selectionData = new SelectionData()

		_updateSelection: ->
			glmvilib.setViewport 0, 0, @_textureDimension, @_textureDimension
			mouse.position.x = @_position.x
			mouse.position.y = @_position.y
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

		getPosition: -> angular.copy @_position

		# returns the updated selectionData associated with the color
		setPosition: (position) ->
			@_position.x = position.x
			@_position.y = position.y
			@_position.lat = position.lat
			@_position.lng = position.lng

			color: @_color
			data: @_updateSelection()

		getColor: -> @_color

		getColorMap: -> angular.copy @_colorMap

		getColorMaskIndex: -> @_colorMaskIndex