<template>
    <section class="section display is-marginless is-paddingless">
        <div class="container is-fluid" id="toolbar">
            <div class="columns">
                <div class="column">
                    <div class="buttons has-addons">
                        <a class="button" v-bind:class="[viewMode === 'similarity' ? 'is-light' : 'is-dark']">similarity</a>
                        <a class="button" v-bind:class="[viewMode === 'mean' ? 'is-light' : 'is-dark']">mean</a>
                        <a class="button" v-bind:class="[viewMode === 'direct' ? 'is-light' : 'is-dark']">direct</a>
                        <a class="button" v-bind:class="[markerIsActive ? 'is-light' : 'is-dark']" @click="toggleMarker" ><i class="fas fa-map-marker-alt"></i></a>
                    </div>
                </div>
            </div>
        </div>
        <div class="container is-fluid is-marginless is-paddingless" id="map-view">
            <div id="additionals">
                <Histogram ref="histogram" :histogram="histogramData"></Histogram>
                <ColorScale ref="scaleCanvas" :bounds="bounds" :colormapvalues="colormapvalues"></ColorScale>
            </div>
            <div id="map"></div>
        </div>
        <div class="container is-fluid is-marginless" id="spectrum">
                <Spectrum></Spectrum>
        </div>
    </section>
</template>

<script>
    import Histogram from './Histogram.vue'
    import Spectrum from './Spectrum.vue'
    import ColorScale from './ColorScale.vue'

    import Map from '../../node_modules/ol/Map';
    import View from '../../node_modules/ol/View';
    import ImageLayer from 'node_modules/ol/layer/Image';
    import ImageSource from '../utils/ImageCanvas.js';
    import Projection from 'node_modules/ol/proj/Projection';
    import {getCenter} from 'node_modules/ol/extent';

    import RenderHandler from '../utils/RenderHandler.js';


    export default {
        props: [
            'initData'
        ],
        components: {
            Histogram,
            ColorScale,
            Spectrum
        },
        data() {
            return {
                data: this.initData,
                map: undefined,
                renderHandler: undefined,
                timeStampBefore: 0,
                mouse: {
                    x: 0,
                    y: 0
                },
                histogramData: [],
                bounds: {},
                colorMapData: {},
                markerIsActive: false,
                viewMode: 'similarity',
                colormapvalues: {},
            }
        },
        created() {
            // Initialize shader
            this.renderHandler = new RenderHandler(this.data);
            this.renderHandler.createShader();
            this.colormapvalues = this.renderHandler.colorMap.getColorMapValues();
        },
        mounted() {
            // Create map view after html template has loaded
            this.createMap();
            // Todo remove me
            //window.glmvilib.finish();
        },
        methods: {
            createMap() {
                let extent = [0, 0, this.data.canvas.width, this.data.canvas.height];
                let projection = new Projection({
                    code: 'pixel-projection',
                    units: 'pixels',
                    extent: extent,
                });

                this.map = new Map({
                    target: 'map',
                    layers: [
                        new ImageLayer({
                            source: new ImageSource({
                                canvas: this.data.canvas,
                                projection: projection,
                                imageExtent: extent,
                            }),
                        }),
                    ],
                    view: this.view = new View({
                        projection: projection,
                        center: getCenter(extent),
                        resolution: 1,
                        zoomFactor: 2,
                        extent: extent,
                    })
                });
                this.map.getView().fit(extent);

                // Set values for the Intensity Histogram and Color-Scale
                this.histogramData = this.renderHandler.intensityHistogram.histogram;
                this.bounds = this.renderHandler.intensityHistogram.bounds;

                // Todo Remove
                /*
                let ctx = document.getElementById('histogram').getContext("2d");
                ctx.fillStyle = "rgb(200, 0 ,0";
                ctx.fillRect(10, 10, 55, 50);
                */

                // Render and update image on mouse movement
                this.updateView();

            },
            updateView() {
                // Render image to show it before user moves the mouse
                this.renderHandler.render(this.mouse);
                this.map.render();

                // Prevent image smoothing on mouse movement
                this.map.on('precompose', function (evt) {
                    evt.context.imageSmoothingEnabled = false;
                    evt.context.webkitImageSmoothingEnabled = false;
                    evt.context.mozImageSmoothingEnabled = false;
                    evt.context.msImageSmoothingEnabled = false;
                });

                // Add event listener for single click and mouse movement
                this.map.on('singleclick', this.updateOnMouseClick);
                this.map.on('pointermove', this.updateOnMouseMove);
            },
            updateOnMouseMove(event) {
                if(!this.markerIsActive) {
                    // Update if there is a certain time interval (in ms) between movements
                    // Todo Maybe change interval for larger datasets, rendering is laggy with the largest set
                    if (event.originalEvent.timeStamp - this.timeStampBefore > 50) {
                        this.updateMousePosition(event);
                        this.timeStampBefore = event.originalEvent.timeStamp;
                    }
                }

            },
            updateOnMouseClick(event) {
                if(!this.markerIsActive) {
                    this.markerIsActive = true;
                }
                this.updateMousePosition(event);

            },
            // Updates relative mouse position and rerenders the map
            updateMousePosition(event) {
                this.mouse.x = event.coordinate[0] / this.data.canvas.width;
                this.mouse.y = event.coordinate[1] / this.data.canvas.height;

                if (this.mouse.x <= 1 && this.mouse.y <= 1 && this.mouse.x >= 0 && this.mouse.y >= 0) {
                    this.renderHandler.render(this.mouse);
                    this.map.render();
                    this.updateHistogram();
                }
            },
            toggleMarker() {
                // Deactivate Marker
                if(this.markerIsActive) {
                    this.markerIsActive = false;
                    return;
                }
                this.markerIsActive = true;
            },
            updateHistogram() {
                this.$refs.histogram.redrawHistogram();
                this.$refs.scaleCanvas.redrawScale();
            }

        }
    }
</script>

<style scoped>

    .display {
    }

    #map-view {
    }

    #map {
        width: 100%;
        background-color: #1f1f1f;
        height: 60vh;
        min-height: 300px;
    }

    #spectrum {
        height: 35vh;
        background-color: #454545;
    }

    #toolbar {
        padding: 2px;
        margin: 0;
        height: 38px;
        background-color: #292929;
    }

    .marker {
        margin-left: 50px;
    }

    #additionals {
        display: flex;
        position: absolute;
        z-index: 99999;
        padding: 5px;
        right: 10px;
        top: 10px;
        width: 80px;
        height: 266px;
        background-color: rgba(41, 41, 41, 0.8);
        border-radius: 10px;
    }

</style>