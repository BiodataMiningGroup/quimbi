# directive to make the autofocus attribute of an input field working
# in dynamically added views
angular.module('quimbi').directive 'autofocus', ->
	restrict: 'A'
	link: (scope, element) ->	do element[0].focus