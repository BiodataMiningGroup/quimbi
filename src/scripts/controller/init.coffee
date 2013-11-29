angular.module('quimbi').controller 'initCtrl', ($scope, $http, state) ->
	$scope.data =
		files: [
			'data/small-stacked-max.txt'
		]

	success = (data, status) ->
		if 200 <= status < 300
			try
				$scope.setInput data
				state.to 'loading'
			catch e
				$scope.$emit 'message::error', "The selected file couldn't be parsed. Error: #{e.message}"
		else
			$scope.$emit 'message::error', "The selected file couldn't be loaded. Status code: #{status}"

	error = (data, status) ->
		$scope.$emit 'message::warning', "It appears the selected file doesn't exist. Status code: #{status}"

	$scope.submitForm = (form) ->
		if form.$valid
			try
				$http.get(form.file).success(success).error(error)
			catch e
				$scope.$emit 'message::warning', "#{e.message}"
		else
			$scope.$emit 'message::info', "Please enter a valid URL."
			
	return