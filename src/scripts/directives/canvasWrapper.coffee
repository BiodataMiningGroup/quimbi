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

        # ? legacy comment ? important! because of this the canvasWrapper is a directive and not just a controller

        ####


        inputWidth = canvas.element[0].width
        inputHeight = canvas.element[0].height

        # TODO: max zoom should depend on ratio between input and screen size
        @map = L.map(element[0], {
            maxZoom: 10,
            minZoom:0,
            crs: L.CRS.Simple
        }).setView([0, 0], 0)

        # projection should not repeat itself (also getProjectionBounds and getPixelWorldBounds don't work without it)
        map.options.crs.infinite = false

        console.log inputWidth, inputHeight

        # setup matching LatLng bounds for the input dimensions
        southWest = map.unproject([inputWidth, 0], 5) #map.getMaxZoom())
        northEast = map.unproject([0, inputHeight], 5) #map.getMaxZoom())
        # alternatively: set maxBounds on map options
        maxBounds = new L.LatLngBounds(southWest, northEast)
        map.setMaxBounds maxBounds

        L.canvasOverlay(canvas.element[0], maxBounds).addTo map

        # fit bounds and setting max bounds should happen in the initialization of map to avoid initial animation
        # padding makes sure that there is additional space around the image that can be covered by controls
        map.fitBounds(maxBounds, {
            padding: [10,10]
        })

        map.on 'mousemove', (e) ->
            mouseLatLng = e.latlng
            if maxBounds.contains mouseLatLng
                posX = (mouseLatLng.lng - maxBounds.getWest()) / (maxBounds.getEast() - maxBounds.getWest())
                posY = (mouseLatLng.lat - maxBounds.getNorth()) / (maxBounds.getSouth() - maxBounds.getNorth())
                scope.$emit 'canvasmousemove', {
                    x: posX
                    y: posY
                }

        map.on 'click', (e) ->
            if maxBounds.contains e.latlng
                scope.$emit 'canvasclick', { latlng: e.latlng }

        L.control.scale().addTo map

        toolset.map = map


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
            # ? probably there to trigger canvas scaling on wrapper resize
            settings.canvasWidth = newWidth
            canvas.checkScale newWidth
        scope.$watch 'properties.width', updateWidth

        return

    controller: ($scope) ->
        # updates mouse coordinates and reads current pixel data
        $scope.$on "canvasmousemove", (e, props) ->
            $scope.updateProperties()
            mouse.position.x = props.x
            mouse.position.y = props.y

            unless settings.showColorRatio then return

            # pos = canvas.getPixelPosition mouse.position.x, 1 - mouse.position.y
            # x-position, y-position, x-dimension, y-dimension, color format,
            # number format, destination variable. colorRatio is from parent scope
            #gl.readPixels pos.x, pos.y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, $scope.colorRatio.pixel

        # finishes drawing/selecting of the currently active tool at the current
        # mouse position
        $scope.$on "canvasclick", (e, props) ->
            $scope.$apply ->
                if toolset.drawing()
                    toolset.activeTool().toolpoint.setLatLng(props.latlng).addTo(map)
                    toolset.drawn position: props.latlng
                return

        # TODO is default tool active by default?
        return
