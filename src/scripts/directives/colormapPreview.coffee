# directive to read a local text file
angular.module('quimbi').directive 'colormapPreview', ->
	
	restrict: 'A'

	template: '<canvas width="256" height="1"></canvas>'

	replace: yes

	scope: 
		colormapPreview: '='

	link: (scope, element) ->
		ctx = element[0].getContext '2d'
		imageData = ctx.createImageData 256, 1

		updatePreview = (newColorMap) -> if newColorMap
			for i in [0..255]
				imageData.data[i*4] = newColorMap[i*3]
				imageData.data[i*4+1] = newColorMap[i*3+1]
				imageData.data[i*4+2] = newColorMap[i*3+2]
				imageData.data[i*4+3] = 255

			ctx.putImageData imageData, 0, 0

		scope.$watch 'colormapPreview', updatePreview
			
				
			

		