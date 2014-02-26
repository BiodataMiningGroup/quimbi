/*
 Graticule plugin for Leaflet powered maps.
*/
L.Graticule = L.GeoJSON.extend({

    options: {
        style: {
            color: '#333',
            weight: 1
        },
        interval: 20,
        southWest: L.latLng(-90, -180),
        northEast: L.latLng(90, 180)
    },

    initialize: function (options) {
        L.Util.setOptions(this, options);
        this._layers = {};
        this.south = this.options.southWest.lng;
        this.west = this.options.southWest.lat;
        this.north = this.options.northEast.lng;
        this.east = this.options.northEast.lat;

        if (this.options.sphere) {
            this.addData(this._getFrame());
        } else {
            this.addData(this._getGraticule());
        }
    },

    _getFrame: function() {
        return { "type": "Polygon",
          "coordinates": [
              this._getMeridian(this.south).concat(this._getMeridian(this.north).reverse())
          ]
        };
    },

    _getGraticule: function () {
        var features = [], interval = this.options.interval;

        // Meridians
        for (var lng = 0, north = this.north; lng <= north; lng = lng + interval) {
            features.push(this._getFeature(this._getMeridian(lng), {
                "name": (lng) ? lng.toString() + "° E" : "Prime meridian"
            }));
            if (lng !== 0) {
                features.push(this._getFeature(this._getMeridian(-lng), {
                    "name": lng.toString() + "° W"
                }));
            }
        }

        // Parallels
        for (var lat = 0, east = this.east; lat <= east; lat = lat + interval) {
            features.push(this._getFeature(this._getParallel(lat), {
                "name": (lat) ? lat.toString() + "° N" : "Equator"
            }));
            if (lat !== 0) {
                features.push(this._getFeature(this._getParallel(-lat), {
                    "name": lat.toString() + "° S"
                }));
            }
        }

        return {
            "type": "FeatureCollection",
            "features": features
        };
    },

    _getMeridian: function (lng) {
        lng = this._lngFix(lng);
        var coords = [];
        for (var lat = this.west, east = this.east; lat <= east; lat++) {
            coords.push([lng, lat]);
        }
        return coords;
    },

    _getParallel: function (lat) {
        var coords = [];
        var south = this._lngFix(this.south);
        for (var lng = south, north = this.north; lng <= north; lng++) {
            coords.push([lng, lat]);
        }
        return coords;
    },

    _getFeature: function (coords, prop) {
        return {
            "type": "Feature",
            "geometry": {
                "type": "LineString",
                "coordinates": coords
            },
            "properties": prop
        };
    },

    _lngFix: function (lng) {
        if (lng >= 180) return 179.999999;
        if (lng <= -180) return -179.999999;
        return lng;
    }

});

L.graticule = function (options) {
    return new L.Graticule(options);
};
