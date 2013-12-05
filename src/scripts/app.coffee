# declaration of this app/module
angular.module 'quimbi', [
	'ngRoute'
	'ui.bootstrap'
	'angularmsg'
	]

# configure angularmsg module
angular.module('angularmsg').value 'displayDuration', 5000
angular.module('angularmsg').value 'fadingDuration', 250

angular.module('quimbi').config ($tooltipProvider, $routeProvider) ->
	# configure ui.bootstrap tooltips
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
	# default route
	.otherwise redirectTo: '/init'

	return

