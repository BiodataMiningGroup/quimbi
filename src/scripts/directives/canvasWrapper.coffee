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

        map.on 'mousemove', (e) -> if maxBounds.contains e.latlng
            posX = (e.latlng.lng - maxBounds.getWest()) / (maxBounds.getEast() - maxBounds.getWest())
            posY = (e.latlng.lat - maxBounds.getNorth()) / (maxBounds.getSouth() - maxBounds.getNorth())
            mouse.position.x = posX
            mouse.position.y = posY

        map.on 'click', (e) -> if maxBounds.contains e.latlng
            scope.$apply -> if toolset.drawing()
                toolset.activeTool().toolpoint.setLatLng(e.latlng).addTo(map)
                toolset.drawn mouse.position #props.latlng
                scope.$emit 'canvasWrapper.updateSelection'

        toolset.map = map
        return