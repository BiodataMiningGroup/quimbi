# directive to read a local text file
angular.module('quimbi').directive 'filereader', ->
	
	restrict: 'A'

	template: '<input type="file"/>'

	replace: yes

	scope: 
		filereader: '='

	link: (scope, element) ->
		change = (changeEvent) ->
			reader = new FileReader()
			reader.onload = (loadEvent) ->
				scope.$apply -> scope.filereader =
					data: loadEvent.target.result
					name: changeEvent.target.files[0].name
			# TODO extend with additional attribute to support all 'readAs' operations
			reader.readAsText changeEvent.target.files[0]

		element.bind 'change', change