/*
 * L.CanvasOverlay is used to overlay canvases over the map (to specific geographical bounds).
 */

// TODO lazyly adapted from L.ImageOverlay, works for now

L.CanvasOverlay = L.Class.extend({
    includes: L.Mixin.Events,

    options: {
        opacity: 1
    },

    initialize: function (canvas, bounds, options) { // (Canvas, LatLngBounds, Object)

        this._bounds = L.latLngBounds(bounds);
        this.__canvas = canvas;

        L.setOptions(this, options);
    },

    onAdd: function (map) {

        this._map = map;

        if (!this._canvas) {
            this._initCanvas();
        }

        map._panes.overlayPane.appendChild(this._canvas);

        map.on('viewreset', this._reset, this);

        if (map.options.zoomAnimation && L.Browser.any3d) {
            map.on('zoomanim', this._animateZoom, this);
        }

        this._reset();
    },

    onRemove: function (map) {
        map.getPanes().overlayPane.removeChild(this._canvas);

        map.off('viewreset', this._reset, this);

        if (map.options.zoomAnimation) {
            map.off('zoomanim', this._animateZoom, this);
        }
    },

    addTo: function (map) {
        map.addLayer(this);
        return this;
    },

    setOpacity: function (opacity) {
        this.options.opacity = opacity;
        this._updateOpacity();
        return this;
    },

    // TODO remove bringToFront/bringToBack duplication from TileLayer/Path
    bringToFront: function () {
        if (this._canvas) {
            this._map._panes.overlayPane.appendChild(this._canvas);
        }
        return this;
    },

    bringToBack: function () {
        var pane = this._map._panes.overlayPane;
        if (this._canvas) {
            pane.insertBefore(this._canvas, pane.firstChild);
        }
        return this;
    },

    getAttribution: function () {
        return this.options.attribution;
    },

    _initCanvas: function () {

    	this._canvas = this.__canvas;
        L.DomUtil.addClass(this._canvas, 'leaflet-image-layer');


        if (this._map.options.zoomAnimation && L.Browser.any3d) {
            L.DomUtil.addClass(this._canvas, 'leaflet-zoom-animated');
        } else {
            L.DomUtil.addClass(this._canvas, 'leaflet-zoom-hide');
        }

        this._updateOpacity();

        //TODO createImage util method to remove duplication
        L.extend(this._canvas, {
            galleryimg: 'no',
            onselectstart: L.Util.falseFn,
            onmousemove: L.Util.falseFn,
            onload: L.bind(this._onImageLoad, this),
        });

    },

    _animateZoom: function (e) {
        var map = this._map,
            canvas = this._canvas,
            scale = map.getZoomScale(e.zoom),
            nw = this._bounds.getNorthWest(),
            se = this._bounds.getSouthEast(),

            topLeft = map._latLngToNewLayerPoint(nw, e.zoom, e.center),
            size = map._latLngToNewLayerPoint(se, e.zoom, e.center)._subtract(topLeft),
            origin = topLeft._add(size._multiplyBy((1 / 2) * (1 - 1 / scale)));

        canvas.style[L.DomUtil.TRANSFORM] =
                L.DomUtil.getTranslateString(origin) + ' scale(' + scale + ') ';
    },

    _reset: function () {
        var canvas   = this._canvas,
            topLeft = this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
            size = this._map.latLngToLayerPoint(this._bounds.getSouthEast())._subtract(topLeft);

        L.DomUtil.setPosition(canvas, topLeft);

        canvas.style.width  = size.x + 'px';
        canvas.style.height = size.y + 'px';
    },

    _onImageLoad: function () {
        this.fire('load');
    },

    _updateOpacity: function () {
        L.DomUtil.setOpacity(this._canvas, this.options.opacity);
    }
});

L.canvasOverlay = function (canvas, bounds, options) {
    return new L.CanvasOverlay(canvas, bounds, options);
};
