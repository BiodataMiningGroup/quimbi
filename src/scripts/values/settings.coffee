# stores and provides all settings that can be set by the user
angular.module('quimbi').value 'settings',
	# current distance method
	distMethod: 'angle'
	
	# show the selection points
	showPoints: yes
	
	# show the overlay image
	showOverlay: yes

	# show the color scale
	showColorScale: yes

	# the current overlay opacity
	overlayOpacity: 0

	# currently used color maps (for the markers and ranges)
	colorMaps: ['fire', 'green', 'blue']

	# single colors representing the colorMaps above. markers and regions are
	# displayed in this colors
	colorMapSingleColors: ['red', 'lime', 'blue']

	# current steps of the intro-tour
	tourStep:
		init: 0
		display: 0
		settings: 0

	# the display mode of the display view
	displayMode: 'distances'
