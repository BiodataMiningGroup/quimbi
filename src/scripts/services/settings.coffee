# service for the settings. stores and provides all settings that can be set
# by the user
angular.module('quimbi').service 'settings', ->
	# current distance method
	@distMethod = 'angle'
	
	# show the selection points
	@showPoints = yes
	
	# show the overlay image
	@showOverlay = yes

	# the current overlay opacity
	@overlayOpacity = 0
	
	# show the color ratios
	@showColorRatio = yes
	
	# width of the main canvas
	@canvasWidth = 0

	# don't upscale the canvas via css but render it larger (needed for pixelated
	# image in Chrome)
	@renderUpscale = no

	return