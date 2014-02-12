# main application controller. parent of all route controllers. manages messaging
# system
angular.module('quimbi').controller 'mainCtrl', ($scope, msg) ->
	# some global properties that need to be shared between controllers
	$scope.properties =
		# disable the about link that could destroy the loading process
		disableAbout: no

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

	return