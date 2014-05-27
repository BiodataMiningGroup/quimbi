# stores and provides all settings that can be set by the user
angular.module('quimbi').value 'settings',
	# current distance method
	distMethod: 'angle'

	# show the selection points
	showPoints: yes

	# show the overlay image
	showOverlay: yes

	# show the background image
	showBackground: yes

	# show the color scale
	showColorScale: yes

	# use background-canvas blending
	useBlending: no

	# the current overlay opacity
	overlayOpacity: 0

	# show the grid
	showGrid: yes

	# color map if only one selection (marker/range/...) is present
	singleSelectionColorMap: 'fire'

	# single color representing the colorMap above. marker or region is
	# displayed in this color
	singleSelectionSingleColor: 'white'

	# color maps if multiple selections are present
	colorMaps: ['red', 'green', 'blue']

	# show the grid
	spaceFillPercent: 1.0

	# single colors representing the colorMaps above. markers and regions are
	# displayed in this colors
	colorMapSingleColors: ['red', 'lime', 'blue']

	# the currrntly active color maps for each color channel
	activeColorMaps: [null, null, null]

	# current steps of the intro-tour
	tourStep:
		init: 0
		display: 0
		settings: 0

	# the display mode of the display view
	displayMode: 'similarity'
