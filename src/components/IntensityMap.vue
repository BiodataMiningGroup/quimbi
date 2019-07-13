<style scoped>

.map {
    height: 100%;
    width: 100%;
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
            <option value="">None</option>
            <option>Point</option>
            <option>Polygon</option>
            <option>Circle</option>
            <option>Square</option>
        </select>
    </form>
    <div ref="intensitymap" id="intensitymap" class="map">

    </div>

</div>

</template>

<script>

import * as d3 from '../../node_modules/d3/dist/d3';
import lasso from '../utils/lasso.js';

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
        'renderHand'
    ],
    data() {
        return {
            data: this.initData,
            intensitymap: undefined,
            renderHandler: this.renderHand,
            mouse: {
                x: 0,
                y: 0
            },
            canvas: undefined,
            canvasWidth: undefined,
            canvasHeight: undefined,
            selectedGeometry: '',
            source: undefined,
            vector: undefined,
            draw: undefined
        }
    },
    mounted() {
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

        /*
         * this.canvas.addEventListener('keydown', (e) => {
         *    if (e.key == 'Control') {
         *        this.addLasso();
         *    }
         * }, false);
         */
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
                    units: 'pixels',
                    extent: extent,
                });

                this.intensitymap = new Map({
                    layers: [
                        new ImageLayer({
                            source: new ImageSource({
                                canvas: this.data.canvas,
                                projection: projection,
                                imageExtent: extent,
                            }),
                        }),
                        this.vector
                    ],
                    target: this.$refs.intensitymap,
                    view: this.view = new View({
                        projection: projection,
                        center: getCenter(extent),
                        resolution: 1,
                        zoomFactor: 2,
                        extent: extent,
                    })
                });
                this.intensitymap.getView().fit(extent);

                //this.createMarker();
                //this.intensitymap.addLayer(this.markerLayer);

                this.updateView();
                // get the OpenLayers sizes of the canvas - which for some reason differ from the html ones (but ehh)
                [this.canvasWidth, this.canvasHeight] = this.intensitymap.getSize();
            },
            addInteraction() {
                let value = this.selectedGeometry;
                if (value !== 'None') {
                    this.draw = new Draw({
                        source: this.source,
                        type: this.selectedGeometry
                    });
                    this.intensitymap.addInteraction(this.draw);
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

            /*
             *  handleLassoEnd(lassoPolygon) {
             *  const selectedPoints = points.filter(d => {
             *  // note we have to undo any transforms done to the x and y to match with the
             *  // coordinate system in the svg.
             *       const x = d.x + padding.left;
             *       const y = d.y + padding.top;
             *
             *        return d3.polygonContains(lassoPolygon, [x, y]);
             *    });
             *
             *    updateSelectedPoints(selectedPoints);
             * },
             *
             * // reset selected points when starting a new polygon
             * handleLassoStart(lassoPolygon) {
             *    this.updateSelectedPoints([]);
             *  },
             *
             * // when we have selected points, update the colors and redraw
             * updateSelectedPoints(selectedPoints) {
             *    // if no selected points, reset to all tomato
             *    if (!selectedPoints.length) {
             *      // reset all
             *        points.forEach(d => {
             *            d.color = 'tomato';
             *        });
             *
             *        // otherwise gray out selected and color selected black
             *    } else {
             *        points.forEach(d => {
             *            d.color = '#eee';
             *        });
             *        selectedPoints.forEach(d => {
             *            d.color = '#000';
             *        });
             *    }
             * },
             * addLasso() {
             *    const interactionSvg = d3.select('#intensitymap')
             *        .append('svg')
             *        .attr('width', this.canvasWidth)
             *        .attr('height', this.canvasHeight)
             *        .style('position', 'absolute')
             *        .style('top', 0)
             *        .style('left', 0);
             *
             *    // attach lasso to interaction SVG
             *    const lassoInstance = lasso()
             *        .on('end', this.handleLassoEnd)
             *        .on('start', this.handleLassoStart);
             *
             *    interactionSvg.call(lassoInstance);
             * },
             */

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
                    evt.context.webkitImageSmoothingEnabled = false;
                    evt.context.mozImageSmoothingEnabled = false;
                    evt.context.msImageSmoothingEnabled = false;
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
