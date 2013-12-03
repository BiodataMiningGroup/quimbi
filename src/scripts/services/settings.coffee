# service for the settings. stores and provides all settings that can be set
# by the user
angular.module('quimbi').service 'settings', ->
	# current distance method
	@distMethod = 'angle'
	
	# show the selection points
	@showPoints = yes
	
	# show the overlay image
	@showOverlay = yes
	
	# show the color scales
	@showScale = yes
	
	# width of the main canvas
	@canvasWidth = 0

	return