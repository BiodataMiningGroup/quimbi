# Range object for the spectrumViewer
angular.module('quimbi').factory 'Range', (settings) ->

	class Range
		
		constructor: (@start) ->
			@offset = 1
			@active = yes
			@group = 'red'

		groups: ['red', 'lime', 'blue']

		class: ->
			output = ''
			if @group and settings.displayMode is 'mean'
				output += "spectrum-viewer__range--#{@group}" 
			output += ' active' if @active
			output

		style: ->
			left: "#{@start - 0.5}px"
			width: "#{@offset}px"
