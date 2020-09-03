<style scoped>

.main {
    display: flex;
    height: 100%;
    width: 100%;
    flex-flow: column;
}

.map-container {
    background-color: #1f1f1f;
    height: 65vh;
    position: relative;
}

.spectrum-container {
    height: 35%;
    position: relative;
    background-color: #353535;
}

.toolbar {
    position: absolute;
    left: 5px;
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
    border-style: solid;
    border-width: 2px;
    border-color: rgba(0, 0, 0, 1);
    border-radius: 5px;
}

.interesting-regions {
    position: absolute;
    height: 65vh;
    width: 100%;
}

select {
    font-size: 1em;
    padding: 0.2em;
    font-family: sans-serif;
}

.coordinates-container {
    display: flex;
    position: absolute;
    z-index: 700;
    right: 100px;
    top: 10px;
    width: 90px;
    height: 60px;
    background-color: rgba(41, 41, 41, 0.8);
    border-style: solid;
    border-color: rgba(0, 0, 0, 1);
    border-width: 2px;
    border-radius: 5px;
    font-weight: bold;
    font-size: 1.1em;
    padding-left: 10px;
}

#spectrum-buttons-container {
    display: flex;
    z-index: 700;
    justify-content: flex-end;
}

#redrawAllMean{
    margin: 1px;
    width: 60px;
    width: 55px;
}

#redrawMean{
    margin: 1px;
    width: 60px;
    width: 55px;
}

</style>

<template>

<section id="main" class="main">
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
                <a class="button" v-bind:class="[lockIsActive ? 'is-light' : 'is-dark']" @click="toggleLock"><i v-bind:class="[lockIsActive ? 'fas fa-lock' : 'fas fa-lock-open']"></i></a>
                <a class="button" v-bind:class="[markerIsActive ? 'is-light' : 'is-dark']" @click="toggleMarker"><i class="fas fa-map-marker-alt"></i></a>
            </div>
        </div>
    </div>
    <div class="interesting-regions">
        <RegionsOfInterest ref="roi" :spectralROIs="spectralROIs" :mapROIs="mapROIs" @removespectrum="onRemoveSpectrumROI" @visibilityspectrum="onVisibilitySpectrumROI" @removearea="onRemoveMapROI" @visibilityarea="onVisibilityMapROI" @activationarea="onActivationMapROI"
        @activationspectrum="onActivationSpectrumROI"></RegionsOfInterest>
    </div>
    <div class="map-container">
        <div class="map-overlay">
            <Histogram ref="histogram" :histogram="histogramData"></Histogram>
            <ColorScale ref="scaleCanvas" :bounds="bounds" :colormapvalues="colormapvalues"></ColorScale>
        </div>
        <div class="coordinates-container">
            <ul>
                <li> x: {{xCoord}} </li>
                <li> y: {{yCoord}} </li>
            </ul>
        </div>
        <div>
            <IntensityMap ref="intensitymap" :initData="data" :renderHandler="renderHandler" :mapROIs="mapROIs" :selectedGeometry="selectedGeometry" @mapmousemove="onMapMouseMove($event)" @mapmouseclick="onMapMouseClick($event)" @finishedmap="setMap($event)" @mapleave="onLeaveMap($event)"
            @addarea="onAddMapROI">
            </IntensityMap>
        </div>
    </div>
    <div id="spectrum-buttons-container">
        <a id="redrawAllMean" class="button is-dark" @click="redrawAllMean"><i v-bind:class="'fas fa-chart-bar'"></i></a>
        <a id="redrawMean" class="button" v-bind:class="[toggleRedrawMean ? 'is-light' : 'is-dark']" @click="redrawMean" :disabled="!toggleRedrawMean"><i v-bind:class="[toggleRedrawMean ? 'fas fa-sync' : 'fas fa-sync']"></i></a>
    </div>
    <div class="spectrum-container" id="spectrum">
        <Spectrum ref="spectrum" :xValues="data.channelNames" :yValues="spectralYValues" :renderHandler="renderHandler" :map="map" :spectralROIs="spectralROIs" :xValueIndexMap="xValueIndexMap" @addspectrum="onAddSpectrumROI" @spectrummousemove="onSpectrumMouseMove"></Spectrum>
    </div>
</section>

</template>

<script>

//chart-bar, sync, redo, retweet, undo

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

import * as d3 from '../../node_modules/d3/dist/d3';
import * as _ from 'lodash';

var inside = require('point-in-polygon')
var classifyPoint = require("robust-point-in-polygon")

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
            lockIsActive: false,
            toggleRedrawMean: false,
            colormapvalues: {},
            markerFeature: {},
            markerLayer: {},
            markerStyle: {},
            markerBorderStyle: {},
            spectralROIs: [],
            mapROIs: [],
            selectedGeometry: 'None',
            spectralYValues: [],
            maskCanvas: undefined,
            maskCtx: undefined,
            channelMask: undefined,
            xValueIndexMap: [],
            directColorMask: [1, 0, 0],
            renderedDirectChannel: 0,
            directChannel: 0,
            xCoord:0,
            yCoord:0,
            roiIDs: [],
            roiIDsLastSync: []
        }
    },
    /**
     * Called before screen is rendered. Retrievs colormap array and bounds for the colormap scale
     */
    created() {
        this.createMaskCanvas();
        this.renderHandler.updateRegionMask(this.maskCanvas);
        this.channelMask = new Uint8Array(this.renderHandler.selectionInfoTextureDimension *
            this.renderHandler.selectionInfoTextureDimension * 4
        ).fill(255);
        this.renderHandler.updateChannelMask(this.channelMask, this.data.channelNames.length);

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
        this.channelMask = new Uint8Array(this.renderHandler.selectionInfoTextureDimension *
            this.renderHandler.selectionInfoTextureDimension * 4
        );
        this.data.channelNames.forEach((point, index) => {
            this.xValueIndexMap[point] = index;
        });
    },

    watch: {
        roiIDs() {
            this.toggleRedrawMean = _.xor(this.roiIDs, this.roiIDsLastSync).length > 0 ? true : false;
            /*if (this.roiIDs.length > 0) {
                this.toggleRedrawMean = _.xor(this.roiIDs, this.roiIDsLastSync).length > 0 ? true : false;
            } else {

            }*/
        }
    },

    methods: {
        redrawAllMean() {
            this.data.meanChannel = _.cloneDeep(this.data.allMeanChannel);
            this.roiIDsLastSync = [];
            if (this.roiIDs.length > 0) {
                this.toggleRedrawMean = true;
            }
        },

        redrawMean() {
            this.data.meanChannel = Array(this.renderHandler.framebuffer.spectrumValues.length).fill(0);
            let counter = 0;
            let that = this;
            if (this.mapROIs.some(roiObject => roiObject.active === true)) {
                for (let i = 0; i < this.data.dataHeight; i++) {
                    for (let j = 0; j < this.data.dataWidth; j++) {
                        this.mapROIs.forEach(roiObject => {
                            if (roiObject.active === true) {
                                //if (classifyPoint(roiObject.coords, [j, i]) === 0 || classifyPoint(roiObject.coords, [j, i]) === -1) {
                                if (inside([j, i], roiObject.coords) === true) {
                                    //console.log(j, i)
                                    this.renderHandler.selectionInfo.updateMouse(j / this.data.dataWidth, i / this.data.dataHeight);
                                    glmvilib.render.apply(null, ['selection-info']);
                                    this.renderHandler.framebuffer.updateSpectrum();
                                    if (this.renderHandler.framebuffer.spectrumValues.some(x => x != 0)) {
                                        this.data.meanChannel = this.data.meanChannel.map(function(num, idx) {
                                            return num + that.renderHandler.framebuffer.spectrumValues[idx];
                                        });
                                        counter += 1;
                                    }
                                }
                            }
                        });
                    }
                }
            } else {
                this.redrawAllMean();
            }
            this.roiIDsLastSync = _.cloneDeep(this.roiIDs);
            this.toggleRedrawMean = false;
        },

        onRemoveSpectrumROI(id) {
            let index = this.spectralROIs.findIndex(spectralROI => spectralROI.id.toString() == id);
            if (index > -1) {
                this.spectralROIs.splice(index, 1);
            }
            this.$refs.spectrum.redrawSelectedRegions(d3.zoomTransform(this.$refs.spectrum.canvas));
            this.updateMeanChannelMask();
        },
        onActivationSpectrumROI(id) {
            let index = this.spectralROIs.findIndex(spectralROI => spectralROI.id.toString() == id);
            //if (this.lockIsActive) {
            this.updateMeanChannelMask();
            //}
        },

        onVisibilitySpectrumROI(id) {
            let index = this.spectralROIs.findIndex(spectralROI => spectralROI.id.toString() == id);
            if (index > -1) {
                this.$refs.spectrum.redrawSelectedRegions(d3.zoomTransform(this.$refs.spectrum.canvas));
            }
        },
        onRemoveMapROI(id) {
            let index = this.mapROIs.findIndex(mapROI => mapROI.coords.toString() == id);
            if (index > -1) {
                console.log(this.mapROIs)
                let mapRoiID = this.mapROIs[index].coords.toString()
                this.roiIDs.splice(this.roiIDs.indexOf(mapRoiID), 1);
                this.$refs.intensitymap.updateMapRegions("remove", this.mapROIs[index]);
                this.mapROIs.splice(index, 1);
                this.drawMaskCanvas();
                this.renderHandler.updateRegionMask(this.maskCanvas);
                glmvilib.render.apply(null, ['angle-dist', 'color-lens', 'color-map']);
                this.map.render();
                //this.updateMeanChannel();
            }
        },
        onActivationMapROI(id) {
            let index = this.mapROIs.findIndex(mapROI => mapROI.coords.toString() == id);
            this.drawMaskCanvas();
            this.renderHandler.updateRegionMask(this.maskCanvas);
            glmvilib.render.apply(null, ['angle-dist', 'color-lens', 'color-map']);
            this.map.render();
            //this.updateMeanChannel();
            if (this.mapROIs[index].active === true) {
                this.roiIDs.push(this.mapROIs[index].coords.toString());
            } else {
                this.roiIDs.splice(this.roiIDs.indexOf(this.mapROIs[index].coords.toString()), 1);
            }
        },

        onVisibilityMapROI(id) {
            let index = this.mapROIs.findIndex(mapROI => mapROI.coords == id);
            if (index > -1) {
                this.$refs.intensitymap.updateMapRegions("visibility", this.mapROIs[index]);
            }
        },

        onAddMapROI(mapROI) {
            this.mapROIs.push(mapROI);
            this.drawMaskCanvas();
            this.renderHandler.updateRegionMask(this.maskCanvas);
            glmvilib.render.apply(null, ['angle-dist', 'color-lens', 'color-map']);
            this.map.render();
        },
        onAddSpectrumROI(spectralROI) {
            this.spectralROIs.push(spectralROI);
            //if (this.lockIsActive) {
            this.updateMeanChannelMask();
            //}
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
                    radius: 3,
                    fill: new Fill({
                        color: 'white'
                    })
                })
            });

            // Outer black circle to create border effect around the white circle
            this.markerBorderStyle = new Style({
                image: new Circle({
                    radius: 5,
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
            if ((this.spectralROIs.length === 0 || this.spectralROIs.every(roiObject =>
                    roiObject.active === false
                )) && !this.markerIsActive ) {
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
        /**
         * Called on free mouse movement. Adds small delay between mouse movement events to prevent lag
         * caused by too much rendering
         * @param event
         */
        onMapMouseMove(event) {
            if (!this.markerIsActive && !this.lockIsActive) {
                if (this.spectralROIs.length !== 0 && this.spectralROIs.some(roiObject =>
                        roiObject.active === true
                    )) {
                    this.updateDistancesChannelMask();
                    this.updateMapMousePosition(event);
                    this.renderHandler.selectionInfo.updateMouse(this.mouse.x, this.mouse.y);
                    glmvilib.render.apply(null, ['selection-info']);
                    this.renderHandler.framebuffer.updateSpectrum();
                } else {
                    // Update if there is a certain time interval (in ms) between movements
                    // Todo Maybe change interval for larger datasets, rendering is laggy with the largest set
                    if (event.originalEvent.timeStamp - this.timeStampBefore > 50) {
                        this.updateMapMousePosition(event);
                        this.timeStampBefore = event.originalEvent.timeStamp;
                        this.renderHandler.selectionInfo.updateMouse(this.mouse.x, this.mouse.y);
                        //console.log(this.mouse.x, this.mouse.y)
                        glmvilib.render.apply(null, ['selection-info']);
                        if (this.mouse.x >= 0 && this.mouse.x <= 1 && this.mouse.y >= 0 && this.mouse.y <= 1) {
                            this.renderHandler.framebuffer.updateSpectrum();
                            //console.log(this.renderHandler.framebuffer.spectrumValues)
                            if (this.renderHandler.framebuffer.spectrumValues.some(x => x != 0)) {
                                this.spectralYValues = this.renderHandler.framebuffer.spectrumValues;
                            } else {
                                this.spectralYValues = this.data.meanChannel;
                            }
                        } else {
                            this.spectralYValues = this.data.meanChannel;
                        }
                        this.$refs.spectrum.redrawSpectrum();
                    }
                }
            }
        },

        onLeaveMap(event) {
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

        },

        /**
         * Sets relative mouse position and rerenders the map, histogram and color scale
         * @param event
         */
        updateMapMousePosition(event) {
            // Norm x and y values and prevent webgl coordinate interpolation
            this.mouse.x = (Math.floor(event.coordinate[0]) + 0.5) / this.data.canvas.width;
            this.mouse.y = (Math.floor(event.coordinate[1]) + 0.5) / this.data.canvas.height;
            this.xCoord = Math.floor(event.coordinate[0]);
            this.yCoord = this.data.canvas.height - Math.ceil(event.coordinate[1]);
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
        toggleLock() {
            if (this.lockIsActive) {
                this.lockIsActive = false;
                return;
            }
            this.lockIsActive = true;
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
            if (this.spectralROIs.some(roiObject => roiObject.active === true)) {
                // clear mask
                while (channel--) {
                    this.channelMask[channel] = 0;
                }
                for (let i = 0; i < this.spectralROIs.length; i++) {
                    if (this.spectralROIs[i].active == true) {
                        let offset = this.spectralROIs[i].range-1;
                        activeChannels += offset+1;
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
        updateDistancesChannelMask() {
            this.updateChannelMaskWith();
            glmvilib.render.apply(null, ['angle-dist', 'color-lens', 'color-map']);
            this.map.render();
            this.updateHistogram();
        },

        updateMeanChannelMask() {
            this.updateChannelMaskWith();
            glmvilib.render.apply(null, ['render-mean-ranges', 'color-lens', 'color-map']);
            this.map.render();
            this.updateHistogram();
        },
        createMaskCanvas() {
            this.maskCanvas = document.createElement('canvas');
            this.maskCanvas.width = this.data.canvas.width;
            this.maskCanvas.height = this.data.canvas.height;
            this.maskCtx = this.maskCanvas.getContext('2d');
            this.maskCtx.fillStyle = 'rgba(0, 0, 0, 1)';
            this.maskCtx.fillRect(0, 0, this.maskCanvas.width, this.maskCanvas.height);
        },
        clearMaskCanvas() {
            this.maskCtx.clearRect(0, 0, this.maskCanvas.width, this.maskCanvas.height);
        },
        drawMaskCanvas() {
            if (this.mapROIs.length === 0 || this.mapROIs.every(roiObject =>
                    roiObject.active == false
                )) {
                this.maskCtx.fillRect(0, 0, this.maskCanvas.width, this.maskCanvas.height);
            } else {
                this.clearMaskCanvas();
                for (let i = 0; i < this.mapROIs.length; i++) {
                    if (this.mapROIs[i].active === true) {
                        this.maskCtx.beginPath();
                        this.maskCtx.moveTo(this.mapROIs[i].coords[0][0], this.maskCanvas.height - this.mapROIs[i].coords[0][1]);
                        for (let j = 1; j < this.mapROIs[i].coords.length; j++) {
                            this.maskCtx.lineTo(this.mapROIs[i].coords[j][0], this.maskCanvas.height - this.mapROIs[i].coords[j][1]);
                        }
                        this.maskCtx.closePath();
                        this.maskCtx.fill();
                    }
                }
            }
        },
        /*
        updateMeanChannel() {
            console.log(this.mapROIs)
            this.data.meanChannel = Array(this.renderHandler.framebuffer.spectrumValues.length).fill(0);
            let counter = 0;
            let that = this;
            if (this.mapROIs.some(roiObject => roiObject.active === true)) {
                for (let i = 0; i < this.data.dataHeight; i++) {
                    for (let j = 0; j < this.data.dataWidth; j++) {
                        this.mapROIs.forEach(roiObject => {
                            if (roiObject.active === true) {
                                //if (classifyPoint(roiObject.coords, [j, i]) === 0 || classifyPoint(roiObject.coords, [j, i]) === -1) {
                                if (inside([j, i], roiObject.coords) === true) {
                                    console.log("trigger roi")
                                    this.renderHandler.selectionInfo.updateMouse(j / this.data.dataWidth, i / this.data.dataHeight);
                                    glmvilib.render.apply(null, ['selection-info']);
                                    this.renderHandler.framebuffer.updateSpectrum();
                                    if (this.renderHandler.framebuffer.spectrumValues.some(x => x != 0)) {
                                        this.data.meanChannel = this.data.meanChannel.map(function(num, idx) {
                                            return num + that.renderHandler.framebuffer.spectrumValues[idx];
                                        });
                                        counter += 1;
                                    }
                                }
                            }
                        });
                    }
                }
            } else {
                this.data.meanChannel = _.cloneDeep(this.data.allMeanChannel);
            }
        }*/
    }
}
</script>
