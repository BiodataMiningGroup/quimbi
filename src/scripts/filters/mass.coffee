# cuts a number string to a maximum length
angular.module('quimbi').filter 'mass', ->
	maxLength = 10
	(input) ->
		if input.length > maxLength then "~#{input.substr -maxLength}"
		else input