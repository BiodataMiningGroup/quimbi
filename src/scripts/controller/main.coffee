# main application controller. parent of all route controllers. manages messaging
# system
angular.module('quimbi').controller 'mainCtrl', ($scope, msg) ->
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

	# current step of the angular-tour
	$scope.tourStep = 0

	return