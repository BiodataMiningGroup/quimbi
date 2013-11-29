angular.module 'quimbi', [
	'ngRoute'
	'ui.bootstrap'
	'angularmsg'
	]

angular.module('angularmsg').value 'displayDuration', 5000
angular.module('angularmsg').value 'fadingDuration', 250

angular.module('quimbi').config ($tooltipProvider, $routeProvider) ->
	$tooltipProvider.options
		placement: 'right'
		animation: no
		popupDelay: 1000
		appendToBody: yes

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
		templateUrl: 'views/about.html'
	)
	.when('/settings',
		controller: 'settingsCtrl'
		templateUrl: 'views/settings.html'
	)
	.otherwise
		redirectTo: '/init'

	return

