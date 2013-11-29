angular.module('quimbi').service 'state', ($rootScope, $location) ->
	state = 'init'
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

	updateLocation = -> $location.url "/#{state}"

	# allows only routes that are permitted for this state
	check = (event, next, current) ->
		unless next.$$route?.originalPath in states[state] then updateLocation()
	$rootScope.$on '$routeChangeStart', check

	@to = (newState) ->
		if states[newState]?
			state = newState
			updateLocation()
	return