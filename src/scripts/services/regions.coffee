# manages all existing regions and provides functions to manipulate them
angular.module('quimbi').service 'regions', ($document, Region, input) ->

	# array of all existing regions
	list = []

	# is the user currently selecting regions?
	active = no

	regionMask = $document[0].createElement 'canvas'
	regionMask.width = input.width
	regionMask.height = input.height

	regionMaskCtx = regionMask.getContext '2d'
	# mask regions with rgba(0,0,0,1), the shader uses only the alpha channel to check for masking
	regionMaskCtx.fillStyle = 'rgba(0, 0, 0, 1)'

	# initialize mask as all selected
	regionMaskCtx.fillRect 0, 0, regionMask.width, regionMask.height

	# ray-casting algorithm based on http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
	# copied from https://github.com/substack/point-in-polygon/blob/master/index.js
	pointInPolygon = (point, polygonPoints) ->
		pointX = point.lat
		pointY = point.lng
		inside = no
		xj = polygonPoints[polygonPoints.length - 1].lat
		yj = polygonPoints[polygonPoints.length - 1].lng
		xi = yi = 0

		for polygonPoint in polygonPoints
			xi = polygonPoint.lat
			yi = polygonPoint.lng
			intersect = ((yi > pointY) isnt (yj > pointY)) and
				(pointX < (xj - xi) * (pointY - yi) / (yj - yi) + xi)
			inside = not inside if intersect
			xj = xi
			yj = yi

		inside

	clipLatLngCoords = (latLngCoords, maxBounds) ->
		# clip selection to data bounds
		# clipPolygon does excately what we need but only works for L.Point/L.Bounds instead of L.LatLng/L.LatLngBounds
		# therefore we 'convert' to Point/Bounds
		points = []
		points.push L.point latLng.lat, latLng.lng for latLng in latLngCoords

		bounds = L.bounds L.point(maxBounds.getNorth(), maxBounds.getWest()),
			L.point(maxBounds.getSouth(), maxBounds.getEast())

		# clip to bounds
		points = L.PolyUtil.clipPolygon points, bounds
		# 'convert' back to LatLng and return
		L.latLng point.x, point.y for point in points

	latLngsToPixelCoords = (latLngs, maxBounds) ->
		pixelCoords = []
		maxLng = maxBounds.getWest()
		maxLat = maxBounds.getNorth()
		boundsWidth = maxBounds.getEast() - maxLng
		boundsHeight = maxBounds.getSouth() - maxLat
		canvasWidth = input.width
		canvasHeight = input.height

		for latLng in latLngs
			x = Math.round (latLng.lng - maxLng) / boundsWidth * canvasWidth
			y = Math.round (latLng.lat - maxLat) / boundsHeight * canvasHeight
			pixelCoords.push L.point(x, y)

		pixelCoords

	refreshRegionMask = ->
		regionMaskCtx.clearRect 0, 0, regionMask.width, regionMask.height

		if list.length is 0
			regionMaskCtx.fillRect 0, 0, regionMask.width, regionMask.height
		else for region in list
			positions = region.getPixelCoords()
			regionMaskCtx.beginPath()
			regionMaskCtx.moveTo positions[0].x, positions[0].y
			for i in [1...positions.length]
				regionMaskCtx.lineTo positions[i].x, positions[i].y
			regionMaskCtx.closePath()
			regionMaskCtx.fill()
		regionMask

	@contain = (latLng) ->
		return yes if list.length is 0

		for region in list when pointInPolygon latLng, region.getLatLngCoords()
			return yes

		no

	@add = (regionLayer, maxBounds) ->
		latLngCoords = regionLayer.getLatLngs()
		unless maxBounds.contains regionLayer.getBounds()
			latLngCoords = clipLatLngCoords latLngCoords, maxBounds
			# ignore creation if all points got clipped
			if latLngCoords.length is 0 then return
			# apply changes to the selection
			regionLayer.setLatLngs latLngCoords

		list.push new Region
			layer: regionLayer
			pixelCoords: latLngsToPixelCoords latLngCoords, maxBounds
			latLngCoords: latLngCoords

	@remove = (stamp) ->
		for region, index in list when region.getStamp() is stamp
			list.splice index, 1
			return

	@getList = -> list

	@setActive = -> active = yes

	@setInactive = -> active = no

	@isActive = -> active

	@getRegionMask = -> refreshRegionMask()

	return
