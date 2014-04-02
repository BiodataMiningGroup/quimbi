# Range object for the spectrumViewer
angular.module('quimbi').factory 'Range', (settings, Tool) ->

	class Range
		
		constructor: (@start) ->
			@offset = 1
			@active = yes
			@group = Tool.defaultGroup

		class: ->
			output = ''
			if @group and settings.displayMode is 'mean'
				output += "spectrum-viewer__range--#{@group}" 
			output += ' active' if @active
			output

		style: ->
			left: "#{@start - 0.5}px"
			width: "#{@offset}px"
