angular.module('quimbi').controller 'mainCtrl', ($scope, inputParser, msg) ->
	$scope.input = null

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

	# hook up mvi messaging system
	mviMessage = (text, type) -> 
		$scope.$emit "message::#{type}", text
		$scope.$apply()
	mvi.setMessageCallback mviMessage

	$scope.setInput = (rawInput) -> $scope.input = inputParser.parse rawInput

	return