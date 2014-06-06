# cuts a number string to a maximum length
angular.module('quimbi').filter 'mass', ->
	maxLength = 11
	(input) ->
		if input.length > maxLength then "#{input.substr 0, maxLength}~"
		else input