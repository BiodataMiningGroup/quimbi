/*
 * L.Control.MicroScale is used for displaying metric scale on the map.
 * It's completely based on L.Control.Scale and only modified a little bit to handle smaller units.
 */

L.Control.MicroScale = L.Control.extend({
    options: {
        position: 'bottomleft',
        maxWidth: 100,
        updateWhenIdle: false
    },

    onAdd: function (map) {
        this._map = map;

        var className = 'leaflet-control-scale',
            container = L.DomUtil.create('div', className),
            options = this.options;

        this._addScales(options, className, container);

        map.on(options.updateWhenIdle ? 'moveend' : 'move', this._update, this);
        map.whenReady(this._update, this);

        return container;
    },

    onRemove: function (map) {
        map.off(this.options.updateWhenIdle ? 'moveend' : 'move', this._update, this);
    },

    _addScales: function (options, className, container) {
        this._mScale = L.DomUtil.create('div', className + '-line', container);
    },

    _update: function () {
        var bounds = this._map.getBounds(),
            centerLat = bounds.getCenter().lat,
            halfWorldMeters = 6378137 * Math.PI * Math.cos(centerLat * Math.PI / 180),
            dist = halfWorldMeters * (bounds.getNorthEast().lng - bounds.getSouthWest().lng) / 180,

            size = this._map.getSize(),
            options = this.options,
            maxMeters = 0;

        if (size.x > 0) {
            maxMeters = dist * (options.maxWidth / size.x);
        }

        this._updateScales(options, maxMeters);
    },

    _updateScales: function (options, maxMeters) {
        this._updateMetric(maxMeters);
    },

    _updateMetric: function (maxMeters) {
        var meters = this._getRoundNum(maxMeters);

        this._mScale.style.width = this._getScaleWidth(meters / maxMeters) + 'px';
        this._mScale.innerHTML = meters < 1000 ? meters + ' m' : (meters / 1000) + ' km';
    },


    _getScaleWidth: function (ratio) {
        return Math.round(this.options.maxWidth * ratio) - 10;
    },

    _getRoundNum: function (num) {
        var pow10 = Math.pow(10, (Math.floor(num) + '').length - 1),
            d = num / pow10;

        d = d >= 10 ? 10 : d >= 5 ? 5 : d >= 3 ? 3 : d >= 2 ? 2 : 1;

        return pow10 * d;
    }
});

L.control.microScale = function (options) {
    return new L.Control.MicroScale(options);
};
