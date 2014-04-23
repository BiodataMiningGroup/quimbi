# directive to read a local text file
angular.module('quimbi').directive 'colorScale', (markers) ->
	
	restrict: 'A'

	template: '<canvas width="256" height="256" data-color-scale-canvas=""></canvas>'

	controller: ($scope) ->

		$scope.colorScaleClass = -> switch markers.getList().length
			when 1 then 'color-scale--1d': yes
			when 2 then 'color-scale--2d': yes
			when 3 then 'color-scale--3d': yes
			else {}