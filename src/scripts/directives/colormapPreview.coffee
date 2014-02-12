# directive to read a local text file
angular.module('quimbi').directive 'colormapPreview', ->
	
	restrict: 'A'

	template: '<canvas width="256" height="20"></canvas>'

	replace: yes

	scope: 
		colormapPreview: '='

	link: (scope, element) ->
		ctx = element[0].getContext '2d'
		imageData = ctx.createImageData 256, 1
		height = 20

		updatePreview = (newColorMap) ->
			for i in [0..255]
				imageData.data[i*4] = newColorMap[i*3]
				imageData.data[i*4+1] = newColorMap[i*3+1]
				imageData.data[i*4+2] = newColorMap[i*3+2]
				imageData.data[i*4+3] = 255

			for i in [0..height-1]
				ctx.putImageData imageData, 0, i

		scope.$watch 'colormapPreview', updatePreview
			
				
			

		