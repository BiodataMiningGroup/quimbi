<template>
    <section class="section display is-marginless is-paddingless">
        <div class="level" id="toolbar">
            <div class="level-item has-text-centered">
                <div class="buttons has-addons">
                    <a class="button" v-bind:class="[viewMode === 'similarity' ? 'is-light' : 'is-dark']">similarity</a>
                    <a class="button" v-bind:class="[viewMode === 'mean' ? 'is-light' : 'is-dark']">mean</a>
                    <a class="button" v-bind:class="[viewMode === 'direct' ? 'is-light' : 'is-dark']">direct</a>
                    <a class="button" v-bind:class="[markerIsActive ? 'is-light' : 'is-dark']" @click="toggleMarker"><i
                            class="fas fa-map-marker-alt"></i></a>
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
            <Spectrum ref="spectrum" :xValues="data.channelNames"
                      :yValues="renderHandler.framebuffer.spectrumValues"></Spectrum>
        </div>
    </section>
</template>

<script>
    import Histogram from './Histogram.vue'
    import Spectrum from './Spectrum.vue'
    import ColorScale from './ColorScale.vue'

    import Map from '../../node_modules/ol/Map';
    import View from '../../node_modules/ol/View';
    import Feature from '../../node_modules/ol/Feature';
    import Circle from 'node_modules/ol/style/Circle';
    import Point from 'node_modules/ol/geom/Point';
    import Fill from 'node_modules/ol/style/Fill';
    import ImageLayer from 'node_modules/ol/layer/Image';
    import ImageSource from '../utils/ImageCanvas.js';
    import VectorLayer from 'ol/layer/Vector';
    import VectorSource from '../../node_modules/ol/source/Vector';
    import Style from '../../node_modules/ol/style/Style';
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
                markerFeature: {},
                markerLayer: {},
                markerStyle: {},
                markerBorderStyle: {}
            }
        },
        created() {
            // Initialize shader
            this.renderHandler = new RenderHandler(this.data);
            this.renderHandler.createShader();
            this.colormapvalues = this.renderHandler.colorMap.getColorMapValues();
            this.bounds = this.renderHandler.intensityHistogram.bounds;
        },
        mounted() {
            // Create map view after html template has loaded
            this.createMap();
            // Draw Color-Scale
            this.$refs.scaleCanvas.redrawScale();
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
                this.createMarker();
                this.map.addLayer(this.markerLayer);

                // Set values for the Intensity Histogram and Color-Scale
                this.histogramData = this.renderHandler.intensityHistogram.histogram;
                this.bounds = this.renderHandler.intensityHistogram.bounds;

                // Render and update image on mouse movement
                this.updateView();

            },

            createMarker() {
                // Create marker for click event
                let vectorSource = new VectorSource({
                    features: []
                });

                this.markerStyle = new Style({
                    image: new Circle({
                        radius: 4,
                        fill: new Fill({
                            color: 'white'
                        })
                    })
                });

                this.markerBorderStyle = new Style({
                    image: new Circle({
                        radius: 6,
                        fill: new Fill({
                            color: 'black'
                        })
                    })
                });

                this.markerFeature = new Feature(new Point([0, 0]));

                this.markerLayer = new VectorLayer({
                    source: vectorSource,
                    style: [this.markerBorderStyle, this.markerStyle]
                });
                vectorSource.addFeature(this.markerFeature);
                // Hide marker
                this.markerLayer.setVisible(false);
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

                // Add event listener for marker scaling
                this.map.on('moveend', () => {
                    let zoomLevel = this.map.getView().getZoom();
                    this.markerStyle.getImage(0).setRadius(zoomLevel + 4);
                    this.markerBorderStyle.getImage(1).setRadius(zoomLevel + 6);

                });
            },

            updateOnMouseMove(event) {
                if (!this.markerIsActive) {
                    // Update if there is a certain time interval (in ms) between movements
                    // Todo Maybe change interval for larger datasets, rendering is laggy with the largest set
                    if (event.originalEvent.timeStamp - this.timeStampBefore > 50) {
                        this.updateMousePosition(event);
                        this.timeStampBefore = event.originalEvent.timeStamp;
                    }
                }

            },

            updateOnMouseClick(event) {
                // Set Marker position
                this.markerFeature.getGeometry().setCoordinates([(Math.floor(event.coordinate[0]) + 0.5),
                    (Math.floor(event.coordinate[1]) + 0.5)]);
                if (!this.markerIsActive) {
                    this.markerLayer.setVisible(true);
                    this.markerIsActive = true;
                }
                this.updateMousePosition(event);
                // Todo wohin damit?
                this.renderHandler.selectionInfo.updateMouse(this.mouse.x, this.mouse.y);
                glmvilib.render.apply(null, ['selection-info']);
                this.renderHandler.framebuffer.updateSpectrum();
                this.$refs.spectrum.redrawSpectrum();

            },

            // Updates relative mouse position and rerenders the map
            updateMousePosition(event) {
                // Norm x and y values and prevent webgl coordinate interpolation
                this.mouse.x = (Math.floor(event.coordinate[0]) + 0.5) / this.data.canvas.width;
                this.mouse.y = (Math.floor(event.coordinate[1]) + 0.5) / this.data.canvas.height;

                if (this.mouse.x <= 1 && this.mouse.y <= 1 && this.mouse.x >= 0 && this.mouse.y >= 0) {
                    this.renderHandler.render(this.mouse);
                    this.map.render();
                    this.updateHistogram();
                }
            },

            toggleMarker() {
                // Deactivate Marker
                if (this.markerIsActive) {
                    this.markerIsActive = false;
                    this.markerLayer.setVisible(false);
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

    #map-view {
    }

    #map {
        width: 100%;
        background-color: #1f1f1f;
        height: 65vh;
        min-height: 300px;
        cursor: crosshair;
    }

    #spectrum {
        height: 35vh;
        background-color: #353535;
    }

    #toolbar {
        position: absolute;
        top: 5px;
        z-index: 800;
        width: 100%;
    }

    .marker {
        margin-left: 50px;
    }

    #additionals {
        display: flex;
        position: absolute;
        z-index: 700;
        padding: 5px;
        right: 10px;
        top: 10px;
        width: 80px;
        height: 266px;
        background-color: rgba(41, 41, 41, 0.8);
        border-radius: 10px;
    }

</style>