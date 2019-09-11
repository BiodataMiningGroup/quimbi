<style scoped>

.main {
    display: flex;
    height: 100%;
    width: 100%;
    flex-flow: column;
}

.map-container {
    background-color: #1f1f1f;
    height: 65%;
    position: relative;
}

.spectrum-container {
    height: 35%;
    position: relative;
    background-color: #353535;
}

.toolbar {
    position: absolute;
    top: 5px;
    z-index: 800;
    width: 100%;
}

.map-overlay {
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

select {
    font-size: 1em;
    padding: 0.2em;
    font-family: sans-serif;
}

</style>

<template>

<section class="main">
    <!--
-->
    <div class="toolbar level">
        <div class="level-item has-text-centered">
            <form class="fas">
                <label>Selection geometry</label>
                <select v-model="selectedGeometry">
                    <option>None</option>
                    <option>Polygon</option>
                </select>

            </form>
            <div class="buttons has-addons">
                <!--
        				<a class="button" v-on:click="viewMode='similarity'" v-bind:class="[viewMode === 'similarity' ? 'is-light' : 'is-dark']">similarity</a>
        				<a class="button" v-on:click="viewMode='mean'" v-bind:class="[viewMode === 'mean' ? 'is-light' : 'is-dark']">mean</a>
        				<a class="button" v-on:click="viewMode='direct'" v-bind:class="[viewMode === 'direct' ? 'is-light' : 'is-dark']">direct</a>
                -->
                <a class="button" v-bind:class="[markerIsActive ? 'is-light' : 'is-dark']" @click="toggleMarker"><i class="fas fa-map-marker-alt"></i></a>
            </div>
        </div>
    </div>
    <div class="interesting-regions">
        <RegionsOfInterest ref="roi" :spectralROIs="spectralROIs"></RegionsOfInterest>
    </div>
    <div class="map-container">
        <div class="map-overlay">
            <Histogram ref="histogram" :histogram="histogramData"></Histogram>
            <ColorScale ref="scaleCanvas" :bounds="bounds" :colormapvalues="colormapvalues"></ColorScale>
        </div>
        <div>
            <IntensityMap ref="intensitymap" :initData="data" :renderHandler="renderHandler" :selectedGeometry="selectedGeometry" @mapMouseMove="onMapMouseMove($event)" @mapMouseClick="onMapMouseClick($event)" @finishedMap="setMap($event)" @mapleave="onLeaveMap($event)">
            </IntensityMap>
        </div>
    </div>
    <div class="spectrum-container" id="spectrum">
        <Spectrum ref="spectrum" :xValues="data.channelNames" :yValues="spectralYValues" :channelTextureDimension="renderHandler.selectionInfoTextureDimension" :renderHandler="renderHandler" :map="map" :spectralROIs="spectralROIs" :xValueIndexMap="xValueIndexMap"
        @updatespectralroi="onUpdateSpectralROI" @spectrummousemove="onSpectrumMouseMove" @spectrumenter="onSpectrumEnter"></Spectrum>
    </div>
</section>

</template>

<script>

// Child Compontents
import Histogram from './Histogram.vue'
import Spectrum from './Spectrum.vue'
import ColorScale from './ColorScale.vue'
import IntensityMap from './IntensityMap.vue'
import RegionsOfInterest from './ROIs.vue'

// OpenLayers
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

export default {
    props: [
        'initData',
        'renderHandler'
    ],
    components: {
        Histogram,
        ColorScale,
        Spectrum,
        IntensityMap,
        RegionsOfInterest
    },
    data() {
        return {
            data: this.initData,
            map: undefined,
            timeStampBefore: 0,
            mouse: {
                x: 0,
                y: 0
            },
            histogramData: [],
            bounds: [],
            colorMapData: {},
            markerIsActive: false,
            viewMode: 'similarity',
            colormapvalues: {},
            markerFeature: {},
            markerLayer: {},
            markerStyle: {},
            markerBorderStyle: {},
            spectralROIs: [],
            mapROIs: [],
            mapROIs2Draw: [],
            selectedGeometry: 'None',
            spectralYValues: [],
            channelMask: undefined,
            xValueIndexMap: [],
            passiveColorMask: [0, 0, 0],
            activeColorMask: [0, 0, 0],
            directColorMask: [1, 0, 0],
            renderedDirectChannel: 0,
            directChannel: 0
        }
    },
    /**
     * Called before screen is rendered. Retrievs colormap array and bounds for the colormap scale
     */
    created() {
        this.spectralYValues = this.data.meanChannel;
        this.colormapvalues = this.renderHandler.colorMap.getColorMapValues();
        this.histogramData = this.renderHandler.intensityHistogram.histogram;
        this.bounds = this.renderHandler.intensityHistogram.bounds;
    },
    /**
     * Called after created(), when dom elements are accessible
     */
    mounted() {
        this.updateHistogram();

        // Draw Color-Scale
        this.$refs.scaleCanvas.redrawScale();
        this.createMarker();
        this.channelMask = new Uint8Array(this.channelTextureDimension *
            this.channelTextureDimension * 4
        );
        this.data.channelNames.forEach((point, index) => {
            this.xValueIndexMap[point] = index;
        });
    },
    methods: {

        updateSpectralROIs(updatedSpectralROI) {
                this.spectralROIs = updatedSpectralROI;
            },
            /**
             * Helper to create the marker which gets visible by clicking on a pixel
             */
            createMarker() {
                // Create marker for click event
                let vectorSource = new VectorSource({
                    features: []
                });

                // Inner white circle
                this.markerStyle = new Style({
                    image: new Circle({
                        radius: 6,
                        fill: new Fill({
                            color: 'white'
                        })
                    })
                });

                // Outer black circle to create border effect around the white circle
                this.markerBorderStyle = new Style({
                    image: new Circle({
                        radius: 8,
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
                // Initially hide marker
                this.markerLayer.setVisible(false);
                this.map.addLayer(this.markerLayer);
            },

            onSpectrumMouseMove(closest) {
                if (this.spectralROIs.length === 0 || this.spectralROIs.every(roiObject => {
                        roiObject.visible === false
                    })) {
                    this.renderHandler.setActiveColorMask(this.directColorMask);
                    this.directChannel = this.xValueIndexMap[closest["xValue"]];
                    if (this.renderedDirectChannel !== this.directChannel) {
                        this.renderedDirectChannel = this.directChannel;
                        this.renderHandler.updateDirectChannel(this.renderedDirectChannel);
                        glmvilib.render.apply(null, ['render-channel', 'color-lens', 'color-map']);
                        this.map.render();
                        this.updateHistogram();
                    }
                }
            },

            onUpdateSpectralROI(spectralROIs) {
                this.spectralROIs = spectralROIs;
                this.updateMeanChannelMask();

            },

            /**
             * Called on free mouse movement. Adds small delay between mouse movement events to prevent lag
             * caused by too much rendering
             * @param event
             */
            onMapMouseMove(event) {
                if (!this.markerIsActive) {
                    // Update if there is a certain time interval (in ms) between movements
                    // Todo Maybe change interval for larger datasets, rendering is laggy with the largest set
                    //if (event.originalEvent.timeStamp - this.timeStampBefore > 50) {
                        this.updateMapMousePosition(event);
                        this.timeStampBefore = event.originalEvent.timeStamp;
                        this.renderHandler.selectionInfo.updateMouse(this.mouse.x, this.mouse.y);
                        glmvilib.render.apply(null, ['selection-info']);
                        this.renderHandler.framebuffer.updateSpectrum();
                        if (this.renderHandler.framebuffer.spectrumValues.some(x => x != 0)) {
                            this.spectralYValues = this.renderHandler.framebuffer.spectrumValues;
                        } else {
                            this.spectralYValues = this.data.meanChannel;
                        }
                        this.$refs.spectrum.redrawSpectrum();
                    //}
                }
            },

            onLeaveMap(event) {
                if (!this.markerIsActive) {
                    this.spectralYValues = this.data.meanChannel;
                }
            },
            onSpectrumEnter(event) {
                if (!this.markerIsActive) {
                    this.spectralYValues = this.data.meanChannel;
                }
            },

            /**
             * Sets marker if mouse is clicked, activates button in toolbar, rerenders the image and
             * gets values for the spectrum view
             **/
            onMapMouseClick(event) {
                // Set Marker position
                this.markerFeature.getGeometry().setCoordinates([(Math.floor(event.coordinate[0]) + 0.5), (Math.floor(event.coordinate[1]) + 0.5)]);
                if (!this.markerIsActive) {
                    this.markerLayer.setVisible(true);
                    this.markerIsActive = true;
                }
                this.updateMapMousePosition(event);
                // Todo refactor please
                this.renderHandler.selectionInfo.updateMouse(this.mouse.x, this.mouse.y);
                glmvilib.render.apply(null, ['selection-info']);
                this.renderHandler.framebuffer.updateSpectrum();
                this.$refs.spectrum.redrawSpectrum();

            },

            /**
             * Sets relative mouse position and rerenders the map, histogram and color scale
             * @param event
             */
            updateMapMousePosition(event) {
                // Norm x and y values and prevent webgl coordinate interpolation
                this.mouse.x = (Math.floor(event.coordinate[0]) + 0.5) / this.data.canvas.width;
                this.mouse.y = (Math.floor(event.coordinate[1]) + 0.5) / this.data.canvas.height;

                if (this.mouse.x <= 1 && this.mouse.y <= 1 && this.mouse.x >= 0 && this.mouse.y >= 0) {
                    this.renderHandler.render(this.mouse);
                    this.map.render();
                    this.updateHistogram();
                }
            },

            /**
             * Well, toggles the marker on map and toolbar
             */
            toggleMarker() {
                // Deactivate Marker
                if (this.markerIsActive) {
                    this.markerIsActive = false;
                    this.markerLayer.setVisible(false);
                    return;
                }
                this.markerIsActive = true;
            },

            /**
             * Called to update the histogram and color scale in the ui
             */
            updateHistogram() {
                this.$refs.histogram.redrawHistogram();
                this.$refs.scaleCanvas.redrawScale();
            },

            setMap(map) {
                this.map = map;
            },

            updateChannelMaskWith() {
                let channel = this.data.channelNames.length;

                // number of active channels of the channel mask
                let activeChannels = 0;

                if (this.spectralROIs.length !== 0 && this.spectralROIs.every(roiObject => {
                        roiObject.visible === true
                    })) {
                    // clear mask
                    while (channel--) {
                        this.channelMask[channel] = 0;
                    }
                    for (let i = 0; i < this.spectralROIs.length; i++) {
                        if (this.spectralROIs[i].visible == true) {
                            let offset = this.spectralROIs[i].range;
                            activeChannels += offset;
                            while (offset--) {
                                this.channelMask[this.xValueIndexMap[this.spectralROIs[i].id[0]] + offset] = 255;
                            }
                        }
                    }

                } else {
                    activeChannels = channel;
                    while (channel--) {
                        this.channelMask[channel] = 255;
                    }
                }
                this.renderHandler.updateChannelMask(this.channelMask, activeChannels);
            },
            /*noch nicht fertig - ist aber nicht ganz sooo wichtig*/
            updateDistancesChannelMask() {
                this.updateChannelMaskWith(ranges.list);
                tmpMousePosition = angular.copy(mouse.position);

                for (let marker of Array.from(markers.getList())) {
                    if (marker.isSet()) {
                        clearArray(this.activeColorMask);
                        this.activeColorMask[marker.getIndex()] = 1;
                        this.renderHandler.setActiveColorMask(this.activeColorMask);
                        /*überschreibt das linke durch das rechte*/
                        angular.extend(mouse.position, marker.getPosition());
                        glmvilib.render(...Array.from(this.renderHandler.getActive() || []));
                    }
                }
                /*überschreibt das linke durch das rechte*/
                return angular.extend(mouse.position, tmpMousePosition);
            },

            updateMeanChannelMask() {
                this.passiveColorMask = new Array(this.passiveColorMask.length).fill(0);
                for (let i = 0; i < this.spectralROIs.length; i++) {
                    this.passiveColorMask[i] = 1;
                }
                //this.renderHandler.setpassiveColorMask(this.passiveColorMask);
                // clears image if there are no ranges
                glmvilib.render.apply(null, ['color-map']);
                for (let i = 0; i < this.spectralROIs.length; i++) {
                    this.updateChannelMaskWith();
                    this.activeColorMask = new Array(this.activeColorMask.length).fill(0);
                    this.activeColorMask[i] = 1;
                    this.renderHandler.setActiveColorMask(this.activeColorMask);
                    glmvilib.render.apply(null, ['render-mean-ranges', 'color-lens', 'color-map']);
                }
                this.map.render();
                this.updateHistogram();
                console.log("Pizza")
            },

    }
}

</script>
