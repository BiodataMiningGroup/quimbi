# creates a new Range object. A range represents a selected region of the
# spectrum.
angular.module('quimbi').factory 'Range', (settings) ->

	class Range

		# the group determines which color map the range is assigned to and
		# to which color channel it is rendered (similar to the colorMaskIndex)
		# of a marker
		@groups: [0, 1, 2]

		constructor: (@start) ->

			@offset = 0

			@active = yes

			@_group = Range.groups[0]

		class: ->
			output = ""
			output += "active" if @active

		style: ->
			output =
				left: "#{@start - 0.5}px"
				width: "#{@offset}px"
			if @active and settings.displayMode is 'mean'
				output['border-bottom-color'] = settings.colorMapSingleColors[@_group]
			output

		setGroup: (group) ->	@_group = group if group in Range.groups

		getGroup: -> @_group

		groupColor: -> settings.colorMapSingleColors[@_group]