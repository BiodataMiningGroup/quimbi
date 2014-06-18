# creates a new Range object. A range represents a selected region of the
# spectrum.
angular.module('quimbi').factory 'Range', (settings, ColorGroupObject, ColorGroup, colorGroups, C) ->

	class Range extends ColorGroupObject

		# index of the most recently chosen color group in the colorGroup service
		@mostRecentColorGroup: 0

		# the type (single, multi) of the most recently chosen color group
		# of an active range
		@activeType: ColorGroup.TYPE_SINGLE

		@count: 0

		constructor: (@start) ->

			# a new range is assigned the most recently used color group
			super colorGroups.get Range.mostRecentColorGroup

			@_name = "range-#{Range.count++}"

			@offset = 0

			@_active = yes

		class: ->
			output = ""
			# not active 
			output += "active" if @isActive()

		style: ->
			output =
				'-webkit-transform': "translateX(#{@start - 0.5}px)"
				transform: "translateX(#{@start - 0.5}px)"
				width: "#{@offset}px"
			if @isActive() and settings.displayMode is C.DISPLAY_MODE.MEAN
				output['border-bottom-color'] = @getColor()
			output

		setActive: ->
			@_active = yes
			Range.activeType = @getType()

		setInactive: ->
			@_active = no

		isActive: -> @_active and (Range.activeType is @getType() or settings.displayMode isnt C.DISPLAY_MODE.MEAN) and settings.displayMode isnt C.DISPLAY_MODE.DIRECT

		setGroup: (index) ->
			currentlyActive = @isActive()
			@setColorGroup colorGroups.get index
			# if range was active and now the type has changed, the new type should
			# be the active one
			Range.activeType = @getType() if currentlyActive
			Range.mostRecentColorGroup = index

		getName: -> @_name

		setName: (name) -> @_name