# controller for the settings route
angular.module('quimbi').controller 'settingsCtrl', ($scope, settings, input, colorMap) ->
	$scope.settings = settings

	# additional information that can't be set directly
	$scope.info =
		normMethod: ''
		norm: 0
		hasOverlay: input.overlayImage isnt ''

	$scope.data =
		availableColorMaps: colorMap.getAvailableColorMaps
		colorMapNames: settings.colorMaps
		colorMapFileR: null
		colorMapFileG: null
		colorMapFileB: null
		colorMapR: null
		colorMapG: null
		colorMapB: null

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