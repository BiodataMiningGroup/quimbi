# service for managing all tools of the display route. keeps track on which
# tool is allowed in combination whith which other and calculates the mvi
# renderState.
angular.module('quimbi').service 'toolset', (Tool) ->
	# collection of all tools
	tools = {}
	# id/color of the currently drawing/selecting tool
	drawing = ''
	# array of ids/colors of the currently passive tools
	passive = []
	# current mvi render state
	renderState = mvi.RENDER_NORMAL

	# removes a tool form the list of passive tools
	removePassive = (id) -> passive = passive.filter (pid) -> pid isnt id

	# updates and returns the current render state
	updateRenderState = ->
		state = mvi.RENDER_NORMAL
		switch drawing
			when 'red' then state = mvi.RTT_ACTIVE_R
			when 'lime' then state = mvi.RTT_ACTIVE_G
			when 'blue' then state = mvi.RTT_ACTIVE_B
		for tool in passive
			switch tool
				when 'red' then state += mvi.RTT_PASSIVE_R
				when 'lime' then state += mvi.RTT_PASSIVE_G
				when 'blue' then state += mvi.RTT_PASSIVE_B
		renderState = state

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
		updateRenderState()
		mvi.startRendering()

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
		# save image in rttTexture for combining tools
		unless tool.isDefault then mvi.snapshot()
		# update renderState AFTER snapshot
		updateRenderState()
		mvi.stopRendering()

	# clear the selection of a tool
	@clear = (id) => 
		# end drawing if this tool is drawing
		if id is drawing then @drawn x: 0, y: 0
		# the cleared tool is not passive
		tools[id].passive = no
		removePassive id
		# update rendered image with new renderState
		mvi.renderOnce updateRenderState()

	# returns current render state
	@getRenderState = -> renderState

	# returns whether any tool is drawing
	@drawing = -> drawing isnt ''

	return