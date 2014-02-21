# service for managing all tools of the display route. keeps track on which
# tool is allowed in combination whith which other
angular.module('quimbi').service 'toolset', (Tool, shader, selection) ->
	# collection of all tools
	tools = {}
	# id/color of the currently drawing/selecting tool
	drawing = ''
	# array of ids/colors of the currently passive tools
	passive = []
	# promise to cancel the render loop
	renderPromise = null

	# removes a tool form the list of passive tools
	removePassive = (id) -> passive = passive.filter (pid) -> pid isnt id

	# updates the active and passive color masks for the pseudocolor shaders
	updateColorMasks = ->
		activeMask = [0, 0, 0]
		switch drawing
			when 'gray' then activeMask = [1, 1, 1]
			when 'red' then activeMask[0] = 1
			when 'lime' then activeMask[1] = 1
			when 'blue' then activeMask[2] = 1
		shader.setActiveColorMask activeMask
		# any active tool has to be in the passive mask as well
		passiveMask = activeMask.slice()
		for tool in passive
			switch tool
				when 'gray' then passiveMask = [1, 1, 1]
				when 'red' then passiveMask[0] = 1
				when 'lime' then passiveMask[1] = 1
				when 'blue' then passiveMask[2] = 1
		shader.setPassiveColorMask passiveMask

	# adds and returns new tool. returns existing tool if the id is already existing.
	@add = (id) ->
		# default tool has a $ prefix
		isDefault = id.charAt(0) is '$'
		id = if isDefault then id.substr 1 else id
		# buttons and points register here. the latter registering gets the exsting object
		if tools[id]? then return tools[id]
		# tool drawing if isDefault?
		#drawing = id if isDefault
		tools[id] = new Tool id, isDefault

	# activate a tool for drawing/selecting
	@draw = (id) ->
		tool = tools[id]
		# logic for which tool can be combined with which other. there should be
		# a single default tool which can only be active alone. all non-default
		# tools can be combined
		for own k, v of tools
			# deactivate all drawing tools
			v.drawing = no
			# deactivate all non-default passive tools if default is drawing
			# deactivate passive default in any case
			if tool.isDefault or v.isDefault
				v.passive = no
				removePassive v.id
		# the given tool is now drawing
		tool.drawing = yes
		drawing = id
		# the drawing tool can't be passive
		tool.passive = no
		removePassive id
		if tool.isDefault then shader.setFinal 'color-map-display'
		else shader.setFinal 'pseudocolor-display'
		updateColorMasks()
		renderPromise = glmvilib.renderLoop.apply glmvilib, shader.getActive()

	# finish drawing/selecting
	@drawn = (position) ->
		# do nothing if no tool is drawing
		return if drawing is ''
		tool = tools[drawing]
		# the prevoiusly drawing tool is now passive
		tool.passive = yes
		# add tool to the passive list if it isn't already there
		if passive.indexOf drawing is -1 then passive.push drawing
		# the tool is drawing no longer
		tool.drawing = no
		drawing = ''
		# set the position of the selection
		tool.position.x = position.x
		tool.position.y = position.y
		renderPromise.stop()
		selection.make position

	# clear the selection of a tool
	@clear = (id) => 
		# end drawing if this tool is drawing
		if id is drawing then @drawn x: 0, y: 0
		# the cleared tool is not passive
		tools[id].passive = no
		removePassive id
		updateColorMasks()
		glmvilib.render shader.getFinal()

	# returns whether any tool is drawing
	@drawing = -> drawing isnt ''

	return