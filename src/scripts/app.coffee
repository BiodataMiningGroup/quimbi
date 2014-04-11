# declaration of this app/module
angular.module 'quimbi', [
	'ngRoute'
	'ngCookies'
	'ui.bootstrap'
	'angularmsg'
	'angular-tour'
	]

angular.module('quimbi').config ($tooltipProvider, $routeProvider, msgProvider) ->
	# configure ui.bootstrap tooltips'
	$tooltipProvider.options
		placement: 'right'
		animation: no
		popupDelay: 1000
		appendToBody: yes

	# declare routes
	$routeProvider
	.when('/init',
		controller: 'initCtrl'
		templateUrl: 'views/init.html'
	)
	.when('/loading',
		controller: 'loadingCtrl'
		templateUrl: 'views/loading.html'
	)
	.when('/display',
		controller: 'displayCtrl'
		templateUrl: 'views/display.html'
	)
	.when('/about',
		controller: 'aboutCtrl'
		templateUrl: 'views/about.html'
	)
	.when('/settings',
		controller: 'settingsCtrl'
		templateUrl: 'views/settings.html'
	)
	.when('/selection',
		controller: 'selectionCtrl'
		templateUrl: 'views/selection.html'
	)
	# default route
	.otherwise redirectTo: '/init'

	# configure angularmsg module
	msgProvider.options
		displayDuration: 5000
		fadingDuration: 250

	return

angular.module('quimbi').run (state, tourConfig) ->
	# make sure the state service is always present and has the locations under
	# control. prevents such things as immediately loading this application
	# at #/display
	state.to 'init'

	tourConfig.animation = no