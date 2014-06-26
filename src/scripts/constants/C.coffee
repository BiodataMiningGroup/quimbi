# global constants used by the application
angular.module('quimbi').constant 'C',

	STATE:
		INIT: 'init'
		LOADING: 'loading'
		DISPLAY: 'display'
	
	DISPLAY_MODE:
		MEAN: 'mean'
		SIMILARITY: 'similarity'
		DIRECT: 'direct'

	DISTANCE_METHOD:
		ANGLE: 'angle'
		EUCL: 'eucl'

	COOKIE_ID:
		TOUR: '-quimbi-tour-steps'
