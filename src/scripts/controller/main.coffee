# main application controller. parent of all route controllers. manages messaging
# system
angular.module('quimbi').controller 'mainCtrl', ($scope, msg, $cookieStore, settings, C) ->

	# global messaging system
	messageInfo = (event, text) -> 
		event.stopPropagation()
		msg.info text
	messageWarning = (event, text) ->
		event.stopPropagation()
		msg.warning text
	messageError = (event, text) ->
		event.stopPropagation()
		msg.error text
	messageSuccess = (event, text) ->
		event.stopPropagation()
		msg.success text

	$scope.$on 'message::info', messageInfo
	$scope.$on 'message::warning', messageWarning
	$scope.$on 'message::error', messageError
	$scope.$on 'message::success', messageSuccess

	# current steps of the angular-tour
	$scope.tourStep = angular.extend settings.tourStep, 
		$cookieStore.get(C.COOKIE_ID.TOUR) or {}

	# must return a function to be called (else infinite digest)
	$scope.tourNext = (view) -> 
		-> $scope.tourStep[view]++

	$scope.tourClose = (view) -> $scope.tourStep[view] = -1

	updateTourCookie = (steps) ->	$cookieStore.put C.COOKIE_ID.TOUR, steps
	$scope.$watch 'tourStep', updateTourCookie, yes

	return