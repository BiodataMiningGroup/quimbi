<style scoped>

.map {
    height: 65vh;
    width: auto;
    cursor: crosshair;
}

.form-inline {
    margin: auto;
    width: 60%;
    padding: 10px;
}

</style>

<template>

<div>
    <form class="form-inline">
        <label>Geometry type </label>
        <select v-on:change="resetInteraction" v-model="selectedGeometry">
            <option>None</option>
            <option>Point</option>
            <option>Polygon</option>
            <option>Circle</option>
        </select>
    </form>
    <div ref="intensitymap" id="intensitymap" class="map">

    </div>

</div>

</template>

<script>

import * as d3 from '../../node_modules/d3/dist/d3';

import Map from '../../node_modules/ol/Map';
import View from '../../node_modules/ol/View';
import Feature from '../../node_modules/ol/Feature';
import Circle from 'node_modules/ol/style/Circle';
import Point from 'node_modules/ol/geom/Point';
import Fill from 'node_modules/ol/style/Fill';
import ImageLayer from 'node_modules/ol/layer/Image';
import ImageSource from '../utils/ImageCanvas.js';
import Draw from '../../node_modules/ol/interaction/Draw.js';
import {
    Tile as TileLayer, Vector as VectorLayer
}
from '../../node_modules/ol/layer.js';
import {
    OSM, Vector as VectorSource
}
from '../../node_modules/ol/source.js';
import Polygon from '../../node_modules/ol/geom/Polygon';
import {
    unByKey
}
from '../../node_modules/ol/Observable.js';
import Style from '../../node_modules/ol/style/Style';
import Projection from 'node_modules/ol/proj/Projection';
import {
    getCenter
}
from 'node_modules/ol/extent';

import RenderHandler from '../utils/RenderHandler.js';

export default {
    props: [
        'initData',
        'renderHandler',
        'mapROIs'
    ],
    data() {
        return {
            data: this.initData,
            intensitymap: undefined,
            mouse: {
                x: 0,
                y: 0
            },
            canvas: undefined,
            canvasWidth: undefined,
            canvasHeight: undefined,
            selectedGeometry: 'None',
            source: undefined,
            vector: undefined,
            draw: undefined
        }
    },
    mounted() {
        /**
         * this.source and this.vector create a new layer for saving drawings on the intensitymap
         */
        this.source = new VectorSource({
            wrapX: false
        });

        this.vector = new VectorLayer({
            source: this.source
        });
        // Create map view after html template has loaded
        this.createMap();
        this.makeCanvasAdressable();
        this.canvas.addEventListener('mouseover', (e) => {
            this.canvas.focus();
        }, false);

        this.$emit("finishedMap", this.intensitymap);
    },
    methods: {
        /**
         * Created the openlayers intensitymap with the glmvilib canvas as layer source, adds hidden marker for
         * pixel selection and calls updateView() to watch for mouse movement
         */
        createMap() {
                let extent = [0, 0, this.data.canvas.width, this.data.canvas.height];
                let projection = new Projection({
                    code: 'pixel-projection',
                    units: 'tile-pixels',
                    extent: extent,
                });
                this.view = new View({
                    projection: projection,
                    resolution: 1,
                    zoom: 1
                })

                this.intensitymap = new Map({
                    layers: [
                        new ImageLayer({
                            source: new ImageSource({
                                canvas: this.data.canvas,
                                projection: projection,
                                imageExtent: extent,
                            }),
                            extent: extent
                        }),
                        this.vector
                    ],
                    target: 'intensitymap',
                    view: this.view
                });
                this.intensitymap.getView().fit(extent);

                this.updateView();

                /*
                 * // get the OpenLayers sizes of the canvas - which for some reason differ from the html ones (but ehh)
                 * [this.canvasWidth, this.canvasHeight] = this.intensitymap.getSize();
                 */
            },
            addInteraction() {
                let value = this.selectedGeometry;
                if (value !== 'None') {
                    this.draw = new Draw({
                        source: this.source,
                        type: value,
                        condition: function(e) {
                            if (e.pointerEvent.buttons === 1) {
                                return true;
                            } else {
                                return false;
                            }
                        }
                    });
                    this.intensitymap.addInteraction(this.draw);
                    let listener;
                    let that = this;
                    this.draw.on('drawstart',
                        function(evt) {
                            // set sketch
                            let sketch = evt.feature;
                        }, this);

                    this.draw.on('drawend',
                        function(evt) {
                            let tmpCoords = evt.feature.getGeometry().getCoordinates()[0];
                            let tmpCoord;
                            let coords = [];
                            for (let i = 0; i < tmpCoords.length; i++) {
                                tmpCoord = [Math.round(tmpCoords[i][0]), Math.round(tmpCoords[i][1])];
                                coords.push(tmpCoord);
                            }
                            let roiObject = {
                                type: value,
                                coords: coords
                            };
                            //evt.target.sketchLineCoords_
                            that.mapROIs.push(roiObject);
                            that.createMask(roiObject);
                        }, this);
                }
            },
            resetInteraction() {
                this.intensitymap.removeInteraction(this.draw);
                this.addInteraction();
            },



            /*
             * sets this.canvas to the intensitymap canvas for easier handling.
             */
            makeCanvasAdressable() {
                let olUnselectable = document.getElementsByClassName("ol-unselectable");
                for (let i = 0; i < olUnselectable.length; i++) {
                    if (olUnselectable[i].tagName == "CANVAS") {
                        this.canvas = olUnselectable[i];
                    };
                }
                this.canvas.tabIndex = '2';
            },
            createMask(polygon) {
                let maskCoords = this.intensitymap.getView().calculateExtent();
                maskCoords = maskCoords.map(x => {
                    return Math.round(x)
                });
                console.log("maskCoords", maskCoords);
                let polMaxX = Math.max.apply(null, polygon["coords"].map(function(value, index) {
                    return value[0];
                }));
                let polMinX = Math.min.apply(null, polygon["coords"].map(function(value, index) {
                    return value[0];
                }));
                let polMaxY = Math.max.apply(null, polygon["coords"].map(function(value, index) {
                    return value[1];
                }));
                let polMinY = Math.min.apply(null, polygon["coords"].map(function(value, index) {
                    return value[1];
                }));

                let mask = new Array((Math.abs(maskCoords[0]) + Math.abs(maskCoords[2])) * (Math.abs(maskCoords[1]) + Math.abs(maskCoords[3]))).fill(0);
                console.log("mask", mask);
                let offsetLeftX = polMinX - maskCoords[0];
                if (offsetLeftX < 0) {
                    offsetLeftX = 0;
                }
                let offsetBottomY = polMinY - maskCoords[1];
                if (offsetBottomY < 0) {
                    offsetBottomY = 0;
                }
                let offsetRightX = polMaxX + offsetLeftX;
                if (offsetRightX > maskCoords[2] + offsetLeftX) {
                    offsetRightX = maskCoords[2] + offsetLeftX;
                }
                let offsetTopY = polMaxY + offsetBottomY;
                if (offsetTopY > maskCoords[3] + offsetBottomY) {
                    offsetTopY = maskCoords[3] + offsetBottomY;
                }
                console.log(offsetBottomY, offsetTopY);
                console.log(offsetLeftX, offsetRightX);
                for (let i = offsetBottomY; i < offsetTopY; i++) {
                    for (let j = offsetLeftX; j < offsetRightX; j++) {
                        mask[j + i * (Math.abs(maskCoords[0]) + Math.abs(maskCoords[2]))] = 1;
                    }

                }
                console.log(mask);
            },

            /**
             * Adds event listener for map interaction
             */
            updateView() {
                // Render image once to show something before the mouse is being moved
                //renders the map
                this.renderHandler.render(this.mouse);
                this.intensitymap.render();

                // Prevent image smoothing on mouse movement
                this.intensitymap.on('precompose', function(evt) {
                    evt.context.imageSmoothingEnabled = false;
                    /*
                     * Should be deprecated.
                     *
                     * evt.context.webkitImageSmoothingEnabled = false;
                     * evt.context.mozImageSmoothingEnabled = false;
                     * evt.context.msImageSmoothingEnabled = false;
                     */
                });

                let that = this;
                // Add event listener for single click and mouse movement
                this.intensitymap.on('pointermove', function(event) {
                    //if (event.originalEvent.shiftKey) {
                    that.$emit('MouseMove', event);
                    //}
                });
                this.intensitymap.on('singleclick', function(event) {
                    that.$emit('mouseclick', event);
                });
            },
    }
}

</script>
