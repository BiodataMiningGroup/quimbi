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

	# updates the current render state
	updateRenderState = ->
		state = mvi.RENDER_NORMAL
		switch drawing
			when 'red' then state += mvi.RTT_ACTIVE_R
			when 'lime' then state += mvi.RTT_ACTIVE_G
			when 'blue' then state += mvi.RTT_ACTIVE_B

		for tool in passive
			switch tool
				when 'red' then state += mvi.RTT_PASSIVE_R
				when 'lime' then state += mvi.RTT_PASSIVE_G
				when 'blue' then state += mvi.RTT_PASSIVE_B
		renderState = state

	# add new tool
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
		for own k, v of tools
			# deactivate all drawing tools
			v.drawing = no
			# deactivate all non-default passive tools if default is drawing
			# deactivate passive default in any case
			if tool.isDefault or v.isDefault
				v.passive = no
				removePassive v.id
		tool.drawing = yes
		drawing = id
		# the drawing tool can't be passive
		tool.passive = no
		removePassive id
		updateRenderState()
		mvi.startRendering()

	# finish drawing/selecting
	@drawn = (position) ->
		return if drawing is ''
		tool = tools[drawing]
		tool.passive = yes
		if passive.indexOf drawing is -1 then passive.push drawing
		tool.drawing = no
		drawing = ''
		tool.position.x = position.x
		tool.position.y = position.y
		# save image in rttTexture
		unless tool.isDefault then do mvi.snapshot
		updateRenderState()
		mvi.stopRendering()

	# finish drawing/selecting if cleared tool is drawing, deactivate it in any case
	@clear = (id) => 
		if id is drawing then @drawn()
		removePassive id
		tools[id].passive = no
		# update rendered image
		mvi.renderOnce updateRenderState()

	# returns current render state
	@getRenderState = -> renderState

	return