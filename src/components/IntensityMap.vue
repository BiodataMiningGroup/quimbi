<style scoped>

.map {
    position: absolute;
    height: 65vh;
    width: auto;
    cursor: crosshair;
    z-index: 0;
}

.selection {
    position: absolute;
    height: 65vh;
    width: auto;
    cursor: crosshair;
    z-index: 1;
}

.wrapper {
    position: relative;
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
    <div class="wrapper">
        <div ref="intensitymap" id="intensitymap" class="map">
        </div>
        <div ref="selectionmap" id="selectionmap" class="selection">
        </div>
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
            selectionmap: undefined,
            mouse: {
                x: 0,
                y: 0
            },
            intensityCanvas: undefined,
            selectionCanvas: undefined,
            selectedGeometry: 'None',
            selectionLayer: undefined,
            vectorSource: undefined,
            mapLayer: undefined,
            draw: undefined
        }
    },
    mounted() {
        /**
         * this.source and this.vector create a new layer for saving drawings on the intensitymap
         */
        this.vectorSource = new VectorSource({
            wrapX: false
        });
        // Create map view after html template has loaded
        this.createMap();
        this.makeCanvasAdressable();
        this.intensityCanvas.addEventListener('mouseover', (e) => {
            this.intensityCanvas.focus();
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
                });
                this.mapLayer = new ImageLayer({
                    source: new ImageSource({
                        canvas: this.data.canvas,
                        projection: projection,
                        imageExtent: extent,
                    }),
                    extent: extent,
                    name: "BaseMap"
                });
                this.selectionLayer = new VectorLayer({
                    source: this.vectorSource,
                    name: "DrawLayer"
                });
                this.intensitymap = new Map({
                    layers: [
                        this.mapLayer
                    ],
                    target: 'intensitymap',
                    view: this.view
                });
                this.selectionmap = new Map({
                    layers: [
                        this.selectionLayer
                    ],
                    target: 'selectionmap',
                    view: this.view
                });
                this.intensitymap.getView().fit(extent);
                this.selectionmap.getView().fit(extent);
                this.updateView();
            },
            addInteraction() {
                let value = this.selectedGeometry;
                if (value !== 'None') {
                    this.draw = new Draw({
                        source: this.vectorSource,
                        type: value,
                        condition: function(e) {
                            if (e.pointerEvent.buttons === 1) {
                                return true;
                            } else {
                                return false;
                            }
                        }
                    });
                    this.selectionmap.addInteraction(this.draw);
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
                            that.mapROIs.push(roiObject);
                        }, this);
                }
            },
            resetInteraction() {
                this.selectionmap.removeInteraction(this.draw);
                this.addInteraction();
            },
            /*
             * sets this.canvas to the intensitymap canvas for easier handling.
             */
            makeCanvasAdressable() {
                this.intensityCanvas = document.getElementById("intensitymap").getElementsByTagName("CANVAS")[0];
                this.selectionCanvas = document.getElementById("selectionmap").getElementsByTagName("CANVAS")[0];
                this.intensityCanvas.tabIndex = '2';
            },
            /**
             * Adds event listener for map interaction
             */
            updateView() {
                // Render image once to show something before the mouse is being moved
                // renders the map
                this.renderHandler.render(this.mouse);
                this.intensitymap.render();
                this.selectionmap.render();

                // Prevent image smoothing on mouse movement
                this.intensitymap.on('precompose', function(evt) {
                    evt.context.imageSmoothingEnabled = false;
                });
                this.selectionmap.on('precompose', function(evt) {
                    evt.context.imageSmoothingEnabled = false;
                });
                let that = this;
                // Add event listener for single click and mouse movement
                this.selectionmap.on('pointermove', function(event) {
                    that.$emit('MouseMove', event);
                });
                this.selectionmap.on('singleclick', function(event) {
                    that.$emit('mouseclick', event);
                });
            }
    }
}

</script>
