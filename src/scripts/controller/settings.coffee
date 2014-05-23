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
		# the file objects returned from the file reader directives of the
		# color maps
		colorMapFileR: null
		colorMapFileG: null
		colorMapFileB: null
		colorMapFileSingle: null
		# the color map arrays of the color maps
		colorMapR: null
		colorMapG: null
		colorMapB: null
		colorMapSingle: null

	updateDistMethod = (newDistMethod) ->
		switch newDistMethod
			when 'angle'
				$scope.info.normMethod = input.angleDistNormMethod
				$scope.info.norm = input.maxAngleDist
			when 'eucl'
				$scope.info.normMethod = input.euclDistNormMethod
				$scope.info.norm = input.maxEuclDist

	# tries to parse and add a custom color map from a csv file
	setNewColorMap = (colorMapFile) ->
		name = colorMapFile.name.split('.csv')[0]
		try
			colorMap.add name, colorMapFile.data
			return name
		catch e
			$scope.$emit 'message::error', "Error while reading color map '#{name}'. #{e.message}"

	$scope.$watch 'settings.distMethod', updateDistMethod

	$scope.$watch 'data.colorMapFileR', (colorMapFile) -> if colorMapFile
		settings.colorMaps[0] = setNewColorMap colorMapFile
	$scope.$watch 'data.colorMapFileG', (colorMapFile) -> if colorMapFile
		settings.colorMaps[1] = setNewColorMap colorMapFile
	$scope.$watch 'data.colorMapFileB', (colorMapFile) -> if colorMapFile
		settings.colorMaps[2] = setNewColorMap colorMapFile
	$scope.$watch 'data.colorMapFileSingle', (colorMapFile) -> if colorMapFile
		settings.singleSelectionColorMap = setNewColorMap colorMapFile

	# update the color map previw directives
	$scope.$watchCollection 'settings.colorMaps', (colorMapNames) ->
		$scope.data.colorMapR = colorMap.get colorMapNames[0]
		$scope.data.colorMapG = colorMap.get colorMapNames[1]
		$scope.data.colorMapB = colorMap.get colorMapNames[2]

	$scope.$watch 'settings.singleSelectionColorMap', (colorMapName) ->
		$scope.data.colorMapSingle = colorMap.get colorMapName

	$scope.resetTour = -> 
		settings.tourStep[view] = 0 for view of settings.tourStep
	return