# controller for the settings route
angular.module('quimbi').controller 'settingsCtrl', ($scope, settings, input, colorMap) ->
	$scope.settings = settings

	# additional information that can't be set directly
	$scope.info =
		normMethod: ''
		norm: 0
		hasOverlay: input.overlayImage isnt ''

	$scope.data =
		# function to return the names of all cached color maps
		availableColorMaps: colorMap.getAvailableColorMaps
		# the names of the three currently selected color maps
		colorMapNames: settings.colorMaps
		# the file object returned from the file reader directive of the
		# first color map
		colorMapFileR: null
		# the file object returned from the file reader directive of the
		# second color map
		colorMapFileG: null
		# the file object returned from the file reader directive of the
		# third color map
		colorMapFileB: null
		# the color map array of the first color map
		colorMapR: null
		# the color map array of the second color map
		colorMapG: null
		# the color map array of the third color map
		colorMapB: null

	# updates the color map previw directives
	updateColorMapPreview = ->
		$scope.data.colorMapR = colorMap.get settings.colorMaps[0]
		$scope.data.colorMapG = colorMap.get settings.colorMaps[1]
		$scope.data.colorMapB = colorMap.get settings.colorMaps[2]
	updateColorMapPreview()

	updateDistMethod = (newDistMethod) ->
		switch newDistMethod
			when 'angle'
				$scope.info.normMethod = input.angleDistNormMethod
				$scope.info.norm = input.maxAngleDist
			when 'eucl'
				$scope.info.normMethod = input.euclDistNormMethod
				$scope.info.norm = input.maxEuclDist

	# tries to parse and add a custom color map from a csv file
	setNewColorMap = (colorMapFile, index) -> if colorMapFile
		name = colorMapFile.name.split('.csv')[0]
		try
			colorMap.add name, colorMapFile.data
			$scope.data.colorMapNames[index] = name
		catch e
			$scope.$emit 'message::error', "Error while reading color map '#{name}'. #{e.message}"

	$scope.$watch 'settings.distMethod', updateDistMethod

	$scope.$watch 'data.colorMapFileR', (colorMapFile) ->
		setNewColorMap colorMapFile, 0
	$scope.$watch 'data.colorMapFileG', (colorMapFile) ->
		setNewColorMap colorMapFile, 1
	$scope.$watch 'data.colorMapFileB', (colorMapFile) ->
		setNewColorMap colorMapFile, 2

	$scope.$watchCollection 'data.colorMapNames', updateColorMapPreview

	$scope.resetTour = -> 
		settings.tourStep[view] = 0 for view of settings.tourStep
	return