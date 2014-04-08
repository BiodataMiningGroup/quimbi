# creates a new Range object
angular.module('quimbi').factory 'Range', (settings) ->

	class Range

		@groups: [0, 1, 2]

		@groupColors: ['red', 'lime', 'blue']

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
				output['border-bottom-color'] = Range.groupColors[@_group]
			output

		setGroup: (group) ->	@_group = group if group in Range.groups

		getGroup: -> @_group

		groupColor: -> Range.groupColors[@_group]