<template>
    <div class="visualization" ref="map">
        <div v-if="!ready" class="loading-overlay">
            <div v-if="error" class="alert alert-danger" v-text="errorMessage"></div>
            <LoadingIndicator v-else :size="120" :progress="loaded"></LoadingIndicator>
        </div>
        <ColorScale v-show="ready" ref="colorScale"></ColorScale>
        <div class="area-actions" v-if="ready">
            <button class="area-action-btn" v-if="!spectrumMode" @click="togglePolygonAreaSelection">
                {{ polygonMode ? 'Auswahl abbrechen' : 'Bereich hinzufügen 2D' }}
            </button>
            <button class="area-action-btn" v-if="!polygonMode" @click="toggleSpectrumAreaSelection">
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
import PixelVectorHandler from "../PixelVectorHandler.js";
import ImageHandler from '../ImageHandler';
import ImageLayer from 'ol/layer/Image';
import ImageSource from 'ol/source/ImageStatic';
import LoadingIndicator from './LoadingIndicator.vue';
import OpacitySlider from '../ol/control/OpacitySlider';
import Point from 'ol/geom/Point';
import Projection from 'ol/proj/Projection';
import SimilarityProgram from '../webgl/programs/Similarity';
import Similarity1BitProgram from '../webgl/programs/Similarity1Bit';
import SingleFeatureProgram from '../webgl/programs/SingleFeature';
import StretchIntensityProgram from '../webgl/programs/StretchIntensity';
import Style from 'ol/style/Style';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import WebglHandler from '../webgl/Handler';
import {BlobWriter} from "@zip.js/zip.js";
import {containsCoordinate} from 'ol/extent';
import {Map, View} from 'ol';
import spectrumSelection from '../logic/spectrumSelection.js';
import polygonSelection from "../logic/polygonSelection.js";
import masks from '../logic/masks.js';

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
    mixins: [spectrumSelection, polygonSelection, masks],
    data () {
        return {
            loaded: 0,
            ready: false,
            initialAlphaScaling: 0.1,
            error: null,
            overlayGrayscale: true,
            frozen: false,
            currentlyShownFeature: undefined
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
        // ------------------------------ ! todo: remove
        async test(x,y) {
            const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
            this.updateMousePosition({coordinate: [x, y]});
            await sleep(1000);
            const canvas = document.querySelector(".ol-layer canvas");
            const link = document.createElement("a");
            link.download = `[${x},${y}]-${this.dataset.precision}bit.png`;
            link.href = canvas.toDataURL("image/png");
            link.click();
        },
        // ------------------------------ !
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

            this.polygonLayer = this.setupPolygonLayer();

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
            if (this.dataset.precision === 1) {
                const METRIC = "jaccard";
                this.similarityProgram = new Similarity1BitProgram(this.dataset, METRIC);
            } else {
                this.similarityProgram = new SimilarityProgram(this.dataset);
            }

            this.stretchIntensityProgram = new StretchIntensityProgram(this.dataset);
            this.colorMapProgram = new ColorMapProgram();
            if (this.hasOverlay) {
                this.colorMapProgram.setAlphaScaling(this.initialAlphaScaling);
            }
            this.singleFeatureProgram = new SingleFeatureProgram(this.dataset);

            this.handler.addProgram(this.similarityProgram);
            this.handler.addProgram(this.stretchIntensityProgram);
            this.handler.addProgram(this.colorMapProgram);
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
        renderSingleFeature() {
            this.handler.render([
                    this.singleFeatureProgram,
                    this.stretchIntensityProgram,
                    this.colorMapProgram,
                ])
                .then(this.map.render.bind(this.map))
                .then(this.updateFeatureColorScale);
        },
        async emitHover() {
            this.$emit('hover', await this.pixelVectorHandler.getPixelVector());
        },
        async emitSelect() {
            const pixelVector = await this.pixelVectorHandler.getPixelVector();
            this.$emit('select', pixelVector.slice());
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
                    this.pixelVectorHandler.setMousePosition(newPosition);
                    if (oldPosition[0] !== newPosition[0] || oldPosition[1] !== newPosition[1]) {
                        this.renderSimilarity();
                        this.emitHover();
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
                    let oldPosition = this.pixelVectorHandler.getMousePosition();
                    let newPosition = event.coordinate.map(Math.floor);
                    this.pixelVectorHandler.setMousePosition(newPosition);
                    if (oldPosition[0] !== newPosition[0] || oldPosition[1] !== newPosition[1]) {
                        this.emitSelect();
                        this.$emit('freeze', true);
                    }
                }
            }
        },
        setReady() {
            this.ready = true;
        },
        async showFeature(index) {
            if (this.ready) {
                if (index === null) {
                    this.currentlyShownFeature = undefined;
                    this.stretchIntensityProgram.link(this.similarityProgram);
                    this.renderSimilarity();
                } else {
                    this.currentlyShownFeature = index;
                    this.stretchIntensityProgram.link(this.singleFeatureProgram);
                    this.singleFeatureProgram.setEmptyChannel();
                    await this.updatePolygonMask();
                    if (this.currentlyShownFeature !== index) return;
                    this.renderSingleFeature();
                    await this.singleFeatureProgram.setChannel(index);
                    await this.updatePolygonMask();
                    if (this.currentlyShownFeature !== index) return;
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
                this.pixelVectorHandler = new PixelVectorHandler(this.dataset);

                this.fetchImages()
                    .then(() => this.updatePolygonMask())
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
        // ------------------------------ ! todo: remove
        window.test = this.test;
        // ------------------------------ !
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
        max-height: calc(100% - 210px);
        overflow-y: auto;
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
