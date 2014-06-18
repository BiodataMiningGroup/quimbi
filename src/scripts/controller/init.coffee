# controller for the init route. manages the submit form and loads the dataset file.
angular.module('quimbi').controller 'initCtrl', ($scope, $http, state, inputParser, C, MSG) ->
	# array of predefined dataset files for the typeahead directive
	$scope.data =
		files: [
			'data/small-stacked-max.txt'
			'data/medium-stacked-max.txt'
			'data/large-stacked-max.txt'
			'data/large-stacked.txt'
		]

	# http request finished
	success = (data, status) ->
		# return code for successful download
		if 200 <= status < 300
			try
				inputParser.parse data
				state.to C.STATE.LOADING
			# catches error from inputParser
			catch e
				$scope.$emit 'message::error', "#{MSG.FILE_NOT_PARSED} Error: #{e.message}"
		# return code for no successful download
		else
			$scope.$emit 'message::error', "#{MSG.FILE_NOT_LOADED} Status code: #{status}"

	# http request failed
	error = (data, status) ->
		$scope.$emit 'message::warning', "#{MSG.FILE_DOESNT_EXIST} Status code: #{status}"

	# submit button pressed
	$scope.submitForm = (form) ->
		if form.$valid
			try
				$http.get(form.file).success(success).error(error)
			catch e
				$scope.$emit 'message::warning', "#{e.message}"
		else
			$scope.$emit 'message::info', MSG.ENTER_VALID_URL
			
	return