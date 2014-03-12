# service for managing all tools of the display route. keeps track on which
# tool is allowed in combination whith which other
angular.module('quimbi').service 'toolset', (Tool, shader) ->
	# collection of all tools
	tools = {}
	# id/color of the currently active tool
	active = ''
	# array of ids/colors of the currently passive tools
	passive = []
	# promise to cancel the render loop
	renderPromise = null

	@map = undefined

	# map of SelectionData of every passive tool
	@selections = {}

	# removes a tool form the list of passive tools
	removePassive = (id) ->
		passive = passive.filter (pid) -> pid isnt id
		map.removeLayer tools[id].toolpoint

	# updates the active and passive color masks for the pseudocolor shaders
	updateColorMasks = ->
		activeMask = [0, 0, 0]
		switch active
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

	updateSelections = =>
		delete @selections[id] for id of @selections when id not in passive
		@selections[id] = tools[id].selection for id in passive

	# adds and returns new tool. returns existing tool if the id is already existing.
	@add = (id) ->
		# default tool has a $ prefix
		isDefault = '$' is id.charAt 0
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
		active = id
		# the drawing tool can't be passive
		tool.passive = no
		removePassive id
		if tool.isDefault then shader.setFinal 'color-map-display'
		else shader.setFinal 'pseudocolor-display'
		updateColorMasks()
		renderPromise = glmvilib.renderLoop.apply glmvilib, shader.getActive()

	# finish activity
	@drawn = (position) ->
		# do nothing if no tool is drawing
		return if active is ''
		tool = tools[active]
		tool.position.x = position.x
		tool.position.y = position.y
		# the prevoiusly active tool is now passive
		tool.passive = yes
		# add tool to the passive list if it isn't already there
		if passive.indexOf active is -1 then passive.push active
		# the tool is active no longer
		tool.drawing = no
		active = ''
		renderPromise.stop()
		tool.makeSelection()
		updateSelections()

	# clear the selection of a tool
	@clear = (id) =>
		# end active if this tool is active
		if id is active then @drawn x: 0, y: 0
		# the cleared tool is not passive
		tools[id].passive = no
		removePassive id
		updateColorMasks()
		glmvilib.render shader.getFinal()
		updateSelections()

	# returns whether any tool is drawing
	@drawing = ->
		active isnt ''

	# returns the id of the currently active tool
	@activeTool = ->
		tools[active]

	# @getTools = ->
	# 	tools


	return
