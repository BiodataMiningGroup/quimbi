# directive for the canvas wrapper element in the display route.
# this could be just a controller, too, but the canvas has to be appended to
# the DOM so an "element" is needed.
# updates the mouse position on the canvas
angular.module('quimbi').directive 'canvasWrapper', (canvas, toolset, settings, mouse) ->

    restrict: 'A'

    templateUrl: 'templates/canvasWrapper.html'

    replace: yes

    scope: yes

    link: (scope, element) ->

        imageUrl = 'data/OF_VF1_1CD133.png'

        # important! because of this the canvasWrapper is a directive and not just a controller
        #element.prepend canvas.element

        ####

        map = L.map(element[0], {
            maxZoom: 10,
            minZoom:0,
            crs: L.CRS.Simple
        }).setView([0, 0], 0)

        # not sure how else to set this, getProjectionBounds and getPixelWorldBounds don't work without it
        map.options.crs.infinite = false

        southWest = map.unproject([120, 0], 5) #map.getMaxZoom())
        northEast = map.unproject([0, 50], 5) #map.getMaxZoom())
         # alternatively: set maxBounds on map options
        maxBounds = new L.LatLngBounds(southWest, northEast)
        map.setMaxBounds(maxBounds)

        L.canvasOverlay(canvas.element[0], maxBounds).addTo(map)

        # fit bounds and setting max bounds should happen in the initialization of map to avoid initial animation
        # padding makes sure that there is additional space around the image that can be covered by controls
        map.fitBounds(maxBounds, {
            padding: [10,10]
        })

        map.on 'click', (e) ->
            if maxBounds.contains(e.latlng) then console.log map.project(e.latlng)

        ####

        # set saved element width if one was saved
        if settings.canvasWidth > 0 then element.css 'width', "#{settings.canvasWidth}px"
        # information about the canvasWrapper element
        scope.properties =
            left: 0
            top: 0
            width: 0
            height: 0

        # updates the information about the canvasWrapper element
        # needed for calculating the relative mouse position
        scope.updateProperties = ->
            rect = element[0].getBoundingClientRect()
            properties = scope.properties
            properties.left = rect.left
            properties.top = rect.top
            properties.width = element[0].clientWidth
            properties.height = element[0].clientHeight
        # update once on linking
        scope.updateProperties()

        updateWidth = (newWidth) ->
            settings.canvasWidth = newWidth
            canvas.checkScale newWidth
        scope.$watch 'properties.width', updateWidth

        return

    controller: ($scope) ->

        # updates mouse coordinates and reads current pixel data
        $scope.mousemove = (e) ->
            this.updateProperties()
            mouse.position.x = (e.pageX - $scope.properties.left) / $scope.properties.width
            mouse.position.y = (e.pageY - $scope.properties.top) / $scope.properties.height
            unless settings.showColorRatio then return

            pos = canvas.getPixelPosition mouse.position.x, 1 - mouse.position.y
            # x-position, y-position, x-dimension, y-dimension, color format,
            # number format, destination variable. colorRatio is from parent scope
            #gl.readPixels pos.x, pos.y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, $scope.colorRatio.pixel

        # finishes drawing/selecting of the currently active tool at the current
        # mouse position
        $scope.drawn = -> toolset.drawn x: mouse.position.x, y: mouse.position.y

        # TODO is default tool active by default?
        return
