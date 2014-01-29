# service for managing the shader programs
angular.module('quimbi').service 'shader', (Program, settings) ->
	euclDist = new Program.EuclDist();
	
	@createPrograms = ->
		glmvilib.addProgram euclDist.id, euclDist.vertexShader, euclDist.fragmentShader, euclDist.constructor
		glmvilib.addProgramCallback euclDist.id, euclDist.callback

	@getActive = ->
		active = []
		switch settings.distMethod
			when 'angle' then active.push ''
			when 'eucl' then active.push euclDist.id
		active

	return