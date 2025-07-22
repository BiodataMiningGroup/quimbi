<template>
    <div class="visualization" ref="map">
        <div v-if="!ready" class="loading-overlay">
            <div v-if="error" class="alert alert-danger" v-text="errorMessage"></div>
            <LoadingIndicator v-else :size="120" :progress="loaded"></LoadingIndicator>
        </div>
        <ColorScale v-show="ready" ref="colorScale"></ColorScale>
        <div class="area-actions" v-if="ready">
            <button class="area-action-btn" @click="toggleAreaSelection">
                {{ polygonMode ? 'Auswahl abbrechen' : 'Bereich hinzufügen 2D' }}
            </button>
            <button class="area-action-btn" @click="toggleSpectrumAreaSelection">
                {{ spectrumMode ? 'Auswahl abbrechen' : 'Bereich hinzufügen 1D' }}
            </button>
        </div>
        <div class="area-lists" v-if="ready && (polygonAreas.length || spectrumAreas.length)">
            <div class="area-list" v-if="polygonAreas.length">
                <h4>2D Bereiche</h4>
                <div v-for="(area, index) in polygonAreas" :key="'poly-' + index" class="area-item" @mouseenter="highlightPolygon(area.feature)" @mouseleave="highlightPolygon(null)">
                    <span>{{ area.name }}</span>
                    <button @click="togglePolygonArea(index)">
                        {{ area.active ? 'Deaktivieren' : 'Aktivieren' }}
                    </button>
                    <button @click="deletePolygonArea(index)">Löschen</button>
                </div>
            </div>

            <div class="area-list" v-if="spectrumAreas.length">
                <h4>1D Bereiche</h4>
                <div v-for="(area, index) in spectrumAreas" :key="'spec-' + index" class="area-item" @mouseenter="emitHovered(index)" @mouseleave="emitHovered(null)">
                    <span>{{ area.name }}</span>
                    <button @click="toggleSpectrumArea(index)">
                        {{ area.active ? 'Deaktivieren' : 'Aktivieren' }}
                    </button>
                    <button @click="deleteSpectrumArea(index)">Löschen</button>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import CanvasSource from '../ol/source/Canvas';
import CircleStyle from 'ol/style/Circle';
import ColorButton from '../ol/control/ColorButton';
import ColorMapProgram from '../webgl/programs/ColorMap';
import ColorScale from './ColorScale.vue';
import Feature from 'ol/Feature';
import FillStyle from 'ol/style/Fill';
import ImageHandler from '../ImageHandler';
import ImageLayer from 'ol/layer/Image';
import ImageSource from 'ol/source/ImageStatic';
import LoadingIndicator from './LoadingIndicator.vue';
import OpacitySlider from '../ol/control/OpacitySlider';
import PixelVectorProgram from '../webgl/programs/PixelVector';
import Point from 'ol/geom/Point';
import Projection from 'ol/proj/Projection';
import SimilarityProgram from '../webgl/programs/Similarity';
import SingleFeatureProgram from '../webgl/programs/SingleFeature';
import StretchIntensityProgram from '../webgl/programs/StretchIntensity';
import Style from 'ol/style/Style';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import WebglHandler from '../webgl/Handler';
import {BlobWriter} from "@zip.js/zip.js";
import {containsCoordinate} from 'ol/extent';
import {Map, View} from 'ol';
import {Stroke} from "ol/style.js";
import {LineString, Polygon} from "ol/geom.js";

export default {
    props: {
        dataset: {
            required: true,
            type: Object,
        },
    },
    components: {
        LoadingIndicator,
        ColorScale,
    },
    data () {
        return {
            loaded: 0,
            ready: false,
            initialAlphaScaling: 0.1,
            error: null,
            overlayGrayscale: true,
            frozen: false,
            polygonMode: false,
            polygonSource: null,
            polygonLayer: null,
            drawInteraction: null,
            polygonAreas: [],
            polygonAreaCounter: 0,
            spectrumAreas: [],
            spectrumMode: false,
            spectrumStartPoint: null,
            spectrumEndPoint: null,
            polygonCoords: [],
            clickListener: null,
            tempLineFeature: null,
            highlightFeature: null,
            highlightStyle: null,
            hoveredAreaIndex: null,
        };
    },
    computed: {
        extent() {
            return [0, 0, this.dataset.width, this.dataset.height];
        },
        hasOverlay() {
            return this.dataset.overlay;
        },
        errorMessage() {
            if (this.error) {
                return this.error.message ? this.error.message : this.error;
            }

            return '';
        },
    },
    methods: {
        fetchImages() {
            let imageHandler = new ImageHandler(this.dataset);
            let parallel = 3;
            let tilesLoaded = 0;

            let promises = imageHandler.load(parallel).map((promise) => {
                return promise.then((args) => {
                        this.handler.storeTile(...args);
                    })
                    .then(() => {
                        tilesLoaded += 1
                        this.loaded = tilesLoaded / promises.length;
                    });
            });

            return Promise.all(promises);
        },
        initializeCanvas() {
            let canvas = document.createElement('canvas');
            canvas.width = this.dataset.width;
            canvas.height = this.dataset.height;

            return canvas;
        },
        initializeWebgl(canvas) {
            this.handler = new WebglHandler({
                canvas: canvas,
                width: this.dataset.width,
                height: this.dataset.height,
                depth: this.dataset.depth,
                precision: this.dataset.precision,
                // Reserve units for the similarity, stretch intensity, color map and pixel vector textures.
                reservedUnits: 4,
            });

            window.addEventListener('beforeunload', this.handler.destruct.bind(this.handler));
        },
        async initializeOpenLayers(canvas) {
            let projection = new Projection({
                code: 'image',
                units: 'pixels',
                extent: this.extent,
            });

            this.canvasSource = new CanvasSource({
                canvas: canvas,
                projection: projection,
                imageExtent: this.extent,
            });

            this.imageLayer = new ImageLayer({
                source: this.canvasSource,
                extent: this.extent,
            });

            this.imageLayer.on('prerender', function (event) {
                event.context.imageSmoothingEnabled = false;
            });

            this.imageLayer.on('postrender', function (event) {
                event.context.imageSmoothingEnabled = true;
            });

            this.markerFeature = new Feature(new Point([0, 0]));
            this.markerLayer = new VectorLayer({
                visible: false,
                source: new VectorSource({features: [this.markerFeature]}),
                style: [
                    new Style({
                        image: new CircleStyle({
                            radius: 7,
                            fill: new FillStyle({color: 'white'}),
                        }),
                    }),
                    new Style({
                        image: new CircleStyle({
                            radius: 4,
                            fill: new FillStyle({color: '#fc6600'}),
                        }),
                    }),
                ],
            });

            // POLYGON
            this.polygonSource = new VectorSource();
            this.polygonLayer = new VectorLayer({
                visible: true,
                source: this.polygonSource,
                style: this.getPolygonStyle,
            });


            this.map = new Map({
                target: this.$refs.map,
                layers: [this.imageLayer, this.markerLayer, this.polygonLayer],
                view: new View({
                    projection: projection,
                }),
            });


            if (this.hasOverlay) {
                let slider = new OpacitySlider({
                    opacity: 1 - this.initialAlphaScaling,
                });
                slider.on('change:opacity', this.updateAlphaScaling);
                this.map.addControl(slider);

                let button = new ColorButton();
                button.on('showcolor', () => {
                    this.overlayGrayscale = false;
                });
                button.on('showgrayscale', () => {
                    this.overlayGrayscale = true;
                });
                this.map.addControl(button);

                let overlayData = await this.dataset.overlayEntry.getData(new BlobWriter());

                this.overlayLayer = new ImageLayer({
                    source: new ImageSource({
                        url: URL.createObjectURL(overlayData),
                        projection: projection,
                        imageExtent: this.extent,
                    }),
                    extent: this.extent,
                    visible: false,
                });

                this.overlayLayer.on('prerender', (event) => {
                    event.context.imageSmoothingEnabled = false;
                    if (this.overlayGrayscale) {
                        event.context.filter = 'grayscale(100%)';
                    }
                });

                this.overlayLayer.on('postrender', function (event) {
                    event.context.imageSmoothingEnabled = true;
                    event.context.filter = 'none';
                });

                this.map.getLayers().insertAt(0, this.overlayLayer);
            }

            this.map.getView().fit(this.extent, {
                padding: [10, 10, 10, 10],
            });
        },
        initializePrograms() {
            this.similarityProgram = new SimilarityProgram(this.dataset);
            this.stretchIntensityProgram = new StretchIntensityProgram(this.dataset);
            this.colorMapProgram = new ColorMapProgram();
            if (this.hasOverlay) {
                this.colorMapProgram.setAlphaScaling(this.initialAlphaScaling);
            }
            this.pixelVectorProgram = new PixelVectorProgram(this.dataset);
            this.singleFeatureProgram = new SingleFeatureProgram(this.dataset);

            this.handler.addProgram(this.similarityProgram);
            this.handler.addProgram(this.stretchIntensityProgram);
            this.handler.addProgram(this.colorMapProgram);
            this.handler.addProgram(this.pixelVectorProgram);
            this.handler.addProgram(this.singleFeatureProgram);

            this.stretchIntensityProgram.link(this.similarityProgram);
            this.colorMapProgram.link(this.stretchIntensityProgram);
        },
        renderSimilarity() {
            this.handler.render([
                    this.similarityProgram,
                    this.stretchIntensityProgram,
                    this.colorMapProgram,
                ])
                .then(this.map.render.bind(this.map))
                .then(this.updateSimilarityColorScale);
        },
        renderPixelVector() {
            return this.handler.render([this.pixelVectorProgram]);
        },
        renderSingleFeature() {
            this.handler.render([
                    this.singleFeatureProgram,
                    this.stretchIntensityProgram,
                    this.colorMapProgram,
                ])
                .then(this.map.render.bind(this.map))
                .then(this.updateFeatureColorScale);
        },
        emitHover() {
            this.$emit('hover', this.pixelVectorProgram.getPixelVector());
        },
        emitSelect() {
            this.$emit('select', this.pixelVectorProgram.getPixelVector().slice());
        },
        emitUnselect() {
            this.$emit('select', []);
        },
        updateFeatureColorScale() {
            this.$refs.colorScale.updateStretching(this.singleFeatureProgram.getIntensityStats());
        },
        updateSimilarityColorScale() {
            this.$refs.colorScale.updateStretching(this.similarityProgram.getIntensityStats());
        },
        updateMousePosition(event) {
            if (containsCoordinate(this.extent, event.coordinate)) {
                let oldPosition = this.similarityProgram.getMousePosition();
                let newPosition = event.coordinate.map(Math.floor);
                let inside = this.checkCoorInPolygons(newPosition);

                if (!inside) {
                    this.similarityProgram.setMousePosition([-1, -1]);
                    this.renderSimilarity();
                } else {
                    this.similarityProgram.setMousePosition(newPosition);
                    this.pixelVectorProgram.setMousePosition(newPosition);
                    if (oldPosition[0] !== newPosition[0] || oldPosition[1] !== newPosition[1]) {
                        this.renderSimilarity();
                        this.renderPixelVector().then(this.emitHover);
                    }
                }
            }
        },
        updateMarkerPosition(event) {
            if (this.frozen) {
                this.unfreeze();
                this.markerLayer.setVisible(false);
                return;
            }
            if (containsCoordinate(this.extent, event.coordinate)) {
                if (!this.checkCoorInPolygons(event.coordinate)) return;

                if (this.map.hasFeatureAtPixel(event.pixel)) {
                    this.markerLayer.setVisible(false);
                    this.emitUnselect();
                    this.$emit('freeze', false);
                } else {
                    this.markerLayer.setVisible(true);
                    this.markerFeature.getGeometry().setCoordinates(event.coordinate);
                    let oldPosition = this.pixelVectorProgram.getMousePosition();
                    let newPosition = event.coordinate.map(Math.floor);
                    this.pixelVectorProgram.setMousePosition(newPosition);
                    if (oldPosition[0] !== newPosition[0] || oldPosition[1] !== newPosition[1]) {
                        this.renderPixelVector().then(() => {
                            this.emitSelect();
                            this.$emit('freeze', true);
                        });
                    }
                }
            }
        },
        setReady() {
            this.ready = true;
        },
        showFeature(index) {
            if (this.ready) {
                if (index === null) {
                    this.stretchIntensityProgram.link(this.similarityProgram);
                    this.renderSimilarity();
                } else {
                    this.singleFeatureProgram.setFeatureIndex(index);
                    this.stretchIntensityProgram.link(this.singleFeatureProgram);
                    this.updateMask();
                    this.renderSingleFeature();
                }
            }
        },
        updateAlphaScaling(event) {
            const alphaScaling = 1 - event.target.get('opacity');
            this.colorMapProgram.setAlphaScaling(alphaScaling);
            this.renderSimilarity();
        },
        initDataset() {
            try {
                let canvas = this.initializeCanvas();
                this.initializeOpenLayers(canvas);
                this.initializeWebgl(canvas);
                this.initializePrograms();

                this.fetchImages()
                    .then(() => this.updateMask())
                    .then(() => this.updateSpectrumMask())
                    .then(this.renderSimilarity)
                    .then(this.setReady)
                    .then(() => {
                        if (this.overlayLayer) {
                            this.overlayLayer.setVisible(true);
                        }
                        this.map.on('pointermove', this.updateMousePosition);
                        this.map.on('click', this.updateMarkerPosition);
                    })
                    .catch((e) => {
                        this.error = new Error(`The dataset could not be loaded. ${e.message}`);
                    });
            } catch (e) {
                this.error = new Error(`The dataset could not be loaded. ${e.message}`);
            }
        },

        freeze() {
            this.frozen = true;
            this.map.un('pointermove', this.updateMousePosition);
        },
        unfreeze() {
            this.frozen = false;
            this.map.on('pointermove', this.updateMousePosition);
        },

        toggleAreaSelection() {
            if (this.polygonMode) {
                this.cancelAreaSelection();
            } else {
                this.startAreaSelection();
            }
        },
        startAreaSelection() {
            this.polygonMode = true;
            this.map.un('click', this.updateMarkerPosition);
            this.polygonCoords = [];

            this.tempLineFeature = new Feature(new LineString([]));
            this.tempLineFeature.set('temp', true);
            this.polygonSource.addFeature(this.tempLineFeature);

            this.clickListener = this.handlePolygonClick;
            this.map.on('click', this.clickListener);
            this.map.on('pointermove', this.updateTempLineToMouse);
            window.addEventListener('keydown', this.handlePolygonKeydown);
        },
        cancelAreaSelection() {
            this.polygonMode = false;
            if (this.clickListener) {
                this.map.un('click', this.clickListener);
                this.clickListener = null;
            }
            this.polygonCoords = [];
            this.map.on('click', this.updateMarkerPosition);
            this.map.un('pointermove', this.updateTempLineToMouse);
            window.removeEventListener('keydown', this.handlePolygonKeydown);

            this.clearTempPolygonVisuals();
        },
        handlePolygonKeydown(event) {
            if (event.key === 'Escape' && this.polygonMode) {
                this.cancelAreaSelection();
            }
        },
        updateTempLineToMouse(event) {
            if (!this.polygonCoords.length) return;

            const lastCoord = this.polygonCoords[this.polygonCoords.length - 1];
            const pointerCoord = event.coordinate;

            this.tempLineFeature.getGeometry().setCoordinates([lastCoord, pointerCoord]);
        },
        handlePolygonClick(event) {
            const coord = event.coordinate;

            if (this.polygonCoords.length > 2) {
                const first = this.polygonCoords[0];
                const dx = first[0] - coord[0];
                const dy = first[1] - coord[1];
                const distance = Math.sqrt(dx * dx + dy * dy);

                if (distance < 5) {
                    const polygon = new Polygon([[...this.polygonCoords, first]]);
                    const feature = new Feature(polygon);
                    this.polygonSource.addFeature(feature);
                    this.polygonAreaCounter = this.polygonAreaCounter + 1;

                    this.polygonAreas.push({
                        name: `Polygon: ${this.polygonAreaCounter}`,
                        active: true,
                        feature: feature,
                    });

                    this.validateMarkerInArea();
                    this.clearTempPolygonVisuals();
                    this.cancelAreaSelection();
                    this.updateMask();
                    this.renderSimilarity();
                    return;
                }
            }

            this.polygonCoords.push(coord);

            if (this.polygonCoords.length > 1) {
                const last = this.polygonCoords[this.polygonCoords.length - 2];
                const lineFeature = new Feature(new LineString([last, coord]));
                lineFeature.set('temp', true);
                this.polygonSource.addFeature(lineFeature);
            }
        },
        clearTempPolygonVisuals() {
            const features = this.polygonSource.getFeatures();
            for (let i = features.length - 1; i >= 0; i--) {
                const f = features[i];
                if (f.get('temp')) {
                    this.polygonSource.removeFeature(f);
                }
            }
            this.tempLineFeature = null;
        },
        validateMarkerInArea() {
            const coord = this.markerFeature.getGeometry().getCoordinates();
            const activePolygons = this.getActivePolygons();

            if (activePolygons.length === 0) return;

            const isInsideAny = this.checkCoorInPolygons(coord);

            if (!isInsideAny) {
                this.markerLayer.setVisible(false);
                this.emitUnselect();
                this.$emit('freeze', false);
            }
        },
        togglePolygonArea(index) {
            this.polygonAreas[index].active = !this.polygonAreas[index].active;
            this.validateMarkerInArea();
            this.updateMask();
            this.renderSimilarity();
        },
        deletePolygonArea(index) {
            const feature = this.polygonAreas[index].feature;
            if (feature) this.polygonSource.removeFeature(feature);
            this.polygonAreas.splice(index, 1);
            this.validateMarkerInArea();
            this.updateMask()
            this.renderSimilarity();

            if (this.highlightFeature) {
                this.polygonSource.removeFeature(this.highlightFeature);
                this.highlightFeature = null;
            }
            this.polygonLayer.changed();
        },
        highlightPolygon(feature) {
            if (this.highlightFeature) {
                this.polygonSource.removeFeature(this.highlightFeature);
                this.highlightFeature = null;
            }

            if (feature) {
                this.highlightFeature = feature.clone();
                this.highlightFeature.set('temp', true);
                this.highlightFeature.setStyle(this.highlightStyle);
                this.polygonSource.addFeature(this.highlightFeature);
            }
        },


        toggleSpectrumArea(index) {
            this.spectrumAreas[index].active = !this.spectrumAreas[index].active;
            this.$emit('spectrum-areas-changed', this.spectrumAreas);
            this.updateSpectrumMask();
            this.renderSimilarity();
        },
        deleteSpectrumArea(index) {
            this.spectrumAreas.splice(index, 1);
            this.$emit('spectrum-areas-changed', this.spectrumAreas);
            this.updateSpectrumMask();
            this.renderSimilarity();
        },
        toggleSpectrumAreaSelection() {
            this.spectrumMode = !this.spectrumMode;

            if (!this.spectrumMode) {
                this.spectrumStartPoint = null;
                this.spectrumEndPoint = null;
            }
            this.renderSimilarity();
        },
        handleSpectrumClick(feature) {
            if (!this.spectrumMode) return;

            if (this.spectrumStartPoint === null) {
                this.spectrumStartPoint = feature.index;
            } else {
                this.spectrumEndPoint = feature.index;

                const start = Math.min(this.spectrumStartPoint, this.spectrumEndPoint);
                const end = Math.max(this.spectrumStartPoint, this.spectrumEndPoint);

                const mzStart = Math.round(Number(this.dataset.channels[start]));
                const mzEnd = Math.round(Number(this.dataset.channels[end]));

                const newArea = {
                    name: `Spektrum: ${mzStart} – ${mzEnd}`,
                    active: true,
                    start: start,
                    end: end
                };
                this.spectrumAreas.push(newArea);
                this.$emit('spectrum-areas-changed', this.spectrumAreas);

                this.spectrumStartPoint = null;
                this.spectrumEndPoint = null;
                this.spectrumMode = false;

                this.updateSpectrumMask();
            }
        },
        getActivePolygons() {
            const polygons = [];
            for (let i = 0; i < this.polygonAreas.length; i++) {
                const area = this.polygonAreas[i];
                if (area.active) {
                    polygons.push(area.feature);
                }
            }
            return polygons;
        },
        checkCoorInPolygons(point) {
            const polygons = this.getActivePolygons();

            if (!(polygons.length === 0)) {
                for (const feature of polygons) {
                    const geom = feature.getGeometry();
                    if (geom.intersectsCoordinate(point)) {
                        return true;
                    }
                }
            } else {
                return true;
            }
            return false;
        },
        async generateMaskTexture() {
            const width = this.dataset.width;
            const height = this.dataset.height;
            const maskData = new Uint8Array(width * height * 4);
            const polygons = this.getActivePolygons();

            for (let y = 0; y < height; y++) {
                for (let x = 0; x < width; x++) {
                    const idx = (y * width + x) * 4;
                    let inside = polygons.length === 0;
                    const point = [x, y];
                    inside = this.checkCoorInPolygons(point);

                    if (inside) {
                        maskData[idx] = 255;
                        maskData[idx + 1] = 255;
                        maskData[idx + 2] = 255;
                        maskData[idx + 3] = 255;
                    } else {
                        maskData[idx] = 0;
                        maskData[idx + 1] = 0;
                        maskData[idx + 2] = 0;
                        maskData[idx + 3] = 255;
                    }
                }
            }
            return maskData;
        },
        async updateMask() {
            const maskData = await this.generateMaskTexture();
            const gl = this.handler.getGl();
            const maskTexture = this.handler.getTexture('mask');

            gl.activeTexture(gl.TEXTURE2);
            gl.bindTexture(gl.TEXTURE_2D, maskTexture);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.dataset.width, this.dataset.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, maskData);
        },
        getActiveSpectra() {
            const spectra = [];
            for (let i = 0; i < this.spectrumAreas.length; i++) {
                const area = this.spectrumAreas[i];
                if (area.active) {
                    spectra.push(area);
                }
            }
            return spectra;
        },
        async updateSpectrumMask() {
            const tiles = Math.ceil(this.dataset.depth / 4);

            const width = Math.ceil(Math.sqrt(tiles));
            const height = Math.ceil(tiles / width);

            const pixels = width * height;
            const maskData = new Uint8Array(pixels * 4);
            const spectra = this.getActiveSpectra();
            const hasActiveAreas = !(spectra.length === 0);

            if (!hasActiveAreas) {
                for (let i = 0; i < pixels * 4; i++) {
                    maskData[i] = 255;
                }
            } else {
                for (let i = 0; i < pixels * 4; i++) {
                    maskData[i] = 0;
                }

                for (const area of spectra) {
                    for (let i = area.start; i <= area.end; i++) {
                        if (i >= this.dataset.depth) continue;

                        const tileIndex = Math.floor(i / 4);
                        const channel = i % 4;

                        maskData[tileIndex * 4 + channel] = 255;
                    }
                }
            }
            const gl = this.handler.getGl();
            const maskTexture = this.handler.getTexture('spectrumMask');
            gl.activeTexture(gl.TEXTURE3);
            gl.bindTexture(gl.TEXTURE_2D, maskTexture);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, maskData);
        },
        setHighlightStyle() {
            this.highlightStyle = [
                new Style({ stroke: new Stroke({ color: 'white', width: 16 })}),
                new Style({ stroke: new Stroke({ color: 'rgba(106, 0, 255)', width: 6 })}),
            ];
        },
        getPolygonStyle(feature) {
            for (let i = 0; i < this.polygonAreas.length; i++) {
                const area = this.polygonAreas[i];
                if (area.feature === feature) {
                    if (!area.active) return null;
                    break;
                }
            }

            return [
                new Style({ stroke: new Stroke({ color: 'white', width: 8 }), fill: null }),
                new Style({ stroke: new Stroke({ color: 'rgba(106, 0, 255)', width: 4 }), fill: null }),
            ];
        },
        emitHovered(index) {
            this.$emit('hovered-area-index', index);
        },
    },
    watch: {
        overlayGrayscale() {
            this.map.render();
        },
        dataset(dataset) {
            if (dataset && Object.keys(dataset).length > 0) {
                this.initDataset();
            }
        },
    },
    mounted() {
        this.setHighlightStyle();
    },
};
</script>

<style lang="scss" scoped>
.visualization {
    width: 100%;
    height: 100%;
    position: relative;

    .loading-overlay {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1;
    }

    .color-scale {
        position: absolute;
        top: 1em;
        right: 1em;
        z-index: 1;
    }

    .area-actions {
        position: absolute;
        top: 5em;
        left: 1em;
        z-index: 2;
        display: flex;
        flex-direction: column;
        gap: 0.5em;
    }

    .area-action-btn {
        width: 320px;
        padding: 0.5em 1em;
        font-weight: bold;
        background: #6a00ff;
        color: white;
        border: none;
        border-radius: 5px;
        cursor: pointer;
    }
    .area-lists {
        position: absolute;
        top: 12em;
        left: 1em;
        z-index: 2;
        max-width: 400px;
        background: rgba(255, 255, 255, 1);
        padding: 0.5em;
        border-radius: 5px;
    }
    .area-list {
        margin-bottom: 1em;
    }
    .area-list h4 {
        margin-bottom: 0.5em;
        font-weight: bold;
    }
    .area-item {
        display: grid;
        grid-template-columns: 1fr auto auto;
        align-items: center;
        gap: 0.5em;
        margin-bottom: 1em;
    }
    .area-item button {
        font-size: 1em;
        padding: 0.2em 0.5em;
    }
}
</style>
