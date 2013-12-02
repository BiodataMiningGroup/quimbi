# controller for the init route. manages the submit form and loads the dataset file.
angular.module('quimbi').controller 'initCtrl', ($scope, $http, state) ->
	# array of predefined dataset files for the typeahead directive
	$scope.data =
		files: [
			'data/small-stacked-max.txt'
		]

	# http request finished
	success = (data, status) ->
		# return code for successful download
		if 200 <= status < 300
			try
				$scope.setInput data
				state.to 'loading'
			# catches error from inputParser
			catch e
				$scope.$emit 'message::error', "The selected file couldn't be parsed. Error: #{e.message}"
		# return code for no successful download
		else
			$scope.$emit 'message::error', "The selected file couldn't be loaded. Status code: #{status}"

	# http request failed
	error = (data, status) ->
		$scope.$emit 'message::warning', "It appears the selected file doesn't exist. Status code: #{status}"

	# submit button pressed
	$scope.submitForm = (form) ->
		if form.$valid
			try
				$http.get(form.file).success(success).error(error)
			catch e
				$scope.$emit 'message::warning', "#{e.message}"
		else
			$scope.$emit 'message::info', "Please enter a valid URL."
			
	return