# controller for the display route
angular.module('quimbi').controller 'displayCtrl', (settings) ->
	# set the mvi computingMethod according to the settings
	distMethod = mvi.METHOD_DEFAULT

	switch settings.distMethod
		when 'angle' then distMethod = mvi.METHOD_ANGLE
		when 'mink' then distMethod = mvi.METHOD_MINK
		when 'mink-ignore-zero' then distMethod = mvi.METHOD_MINK_IGNORE_0

	mvi.setComputingMethod distMethod
	return