# service for managing the routes since not every route is allowed/fuctional at
# any time. the application has several states in which only certain routes work
angular.module('quimbi').service 'state', ($rootScope, $location) ->
	# current application state
	state = 'init'
	# defines all possible application states with their allowed routes
	states =
		init: [
			'/init'
			'/about'
		]
		loading: [
			'/loading'
		]
		display: [
			'/display'
			'/about'
			'/settings'
		]

	# sets the route to the current application state
	updateLocation = -> $location.url "/#{state}"

	# allows only routes that are permitted for this state
	check = (event, next, current) ->
		unless next.$$route?.originalPath in states[state] then updateLocation()
	$rootScope.$on '$routeChangeStart', check

	# change the application state
	@to = (newState) ->
		if states[newState]?
			state = newState
			updateLocation()
	return