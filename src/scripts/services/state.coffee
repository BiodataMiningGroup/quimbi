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
			'/selection'
		]

	# sets the route to the current application state
	updateLocation = -> $location.url "/#{state}"

	# allows only routes that are permitted for this state
	check = (event, nextUrl, currentUrl) ->
		next = nextUrl.substr nextUrl.lastIndexOf('#') + 1
		# cancel location change if the url is not allowed in this state
		unless next in states[state] then event.preventDefault()
	$rootScope.$on '$locationChangeStart', check

	# change the application state
	@to = (newState) -> if states[newState]?
		state = newState
		updateLocation()

	@current = -> state
	return