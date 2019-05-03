<template>
<section class="main">
	<div class="toolbar level">
		<div class="level-item has-text-centered">
			<div class="buttons has-addons">
				<a class="button" v-on:click="viewMode='similarity'" v-bind:class="[viewMode === 'similarity' ? 'is-light' : 'is-dark']">similarity</a>
				<a class="button" v-on:click="viewMode='mean'" v-bind:class="[viewMode === 'mean' ? 'is-light' : 'is-dark']">mean</a>
				<a class="button" v-on:click="viewMode='direct'" v-bind:class="[viewMode === 'direct' ? 'is-light' : 'is-dark']">direct</a>
				<a class="button" v-bind:class="[markerIsActive ? 'is-light' : 'is-dark']" @click="toggleMarker"><i class="fas fa-map-marker-alt"></i></a>
			</div>
		</div>
	</div>
	<div class="map-container">
		<div class="map-overlay">
			<Histogram ref="histogram" :histogram="histogramData"></Histogram>
			<ColorScale ref="scaleCanvas" :bounds="bounds" :colormapvalues="colormapvalues"></ColorScale>
		</div>
		<div id="mymap">
			<MyMap ref="mymap" :initData="data" :renderHand="renderHandler" v-on:MouseMove="updateOnMouseMove($event)" v-on:MouseClick="updateOnMouseClick($event)">
			</MyMap>
		</div>
	</div>
	<div class="spectrum-container" id="spectrum">
		<Spectrum ref="spectrum" :xValues="data.channelNames" :yValues="renderHandler.framebuffer.spectrumValues"></Spectrum>
	</div>
</section>
</template>

<script>
// Child Compontents
import Histogram from './Histogram.vue'
import Spectrum from './Spectrum.vue'
import ColorScale from './ColorScale.vue'
import MyMap from './MyMap.vue'

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
import {
	getCenter
} from 'node_modules/ol/extent';


import RenderHandler from '../utils/RenderHandler.js';


export default {
	props: [
		'initData'
	],
	components: {
		Histogram,
		ColorScale,
		Spectrum,
		MyMap
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
			bounds: [],
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
	/**
	 * Called before screen is rendered. Inits the Renderhandler,
	 * retrievs colormap array and bounds for the colormap scale
	 */
	created() {
		// Initialize shader
		this.renderHandler = new RenderHandler(this.data);
		this.renderHandler.createShader();
		this.colormapvalues = this.renderHandler.colorMap.getColorMapValues();
		this.histogramData = this.renderHandler.intensityHistogram.histogram;
		this.bounds = this.renderHandler.intensityHistogram.bounds;
	},
	/**
	 * Called after created(), when dom elements are accessible
	 */
	mounted() {
		// Draw Color-Scale
		this.$refs.scaleCanvas.redrawScale();
	},

	methods: {
		/**
		 * Created the openlayers map with the glmvilib canvas as layer source, adds hidden marker for
		 * pixel selection and calls updateView() to watch for mouse movement
		 */
		/*
		createMap() {
		let extent = [0, 0, this.data.canvas.width, this.data.canvas.height];
		let projection = new Projection({
			code: 'pixel-projection',
			units: 'pixels',
			extent: extent,
		});

		this.map = new Map({
			target: this.$refs.map,
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

		// Render and update image on mouse movement
		this.updateView();

	},
  */
		/**
		 * Helper to create the marker which gets visible by clicking on a pixel
		 */
		/*
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
		},
    */
		/**
		 * Adds event listener for map interaction
		 */
		/*
		updateView() {
			// Render image once to show something before the mouse is being moved
			this.renderHandler.render(this.mouse);
			//this.map.render();

			// Prevent image smoothing on mouse movement
      this.map.on('precompose', function(evt) {
				evt.context.imageSmoothingEnabled = false;
				evt.context.webkitImageSmoothingEnabled = false;
				evt.context.mozImageSmoothingEnabled = false;
				evt.context.msImageSmoothingEnabled = false;
			});

			// Add event listener for single click and mouse movement
			this.map.on('singleclick', this.updateOnMouseClick);
			this.map.on('pointermove', this.updateOnMouseMove);
		},
    */

		/**
		 * Called on free mouse movement. Adds small delay between mouse movement events to prevent lag
		 * caused by too much rendering
		 * @param event
		 */
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

		/**
		 * Sets marker if mouse is clicked, activates button in toolbar, rerenders the image and
		 * gets values for the spectrum view
		 **/
		updateOnMouseClick(event) {
			// Set Marker position
			this.markerFeature.getGeometry().setCoordinates([(Math.floor(event.coordinate[0]) + 0.5),
				(Math.floor(event.coordinate[1]) + 0.5)
			]);
			if (!this.markerIsActive) {
				this.markerLayer.setVisible(true);
				this.markerIsActive = true;
			}
			this.updateMousePosition(event);
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
		updateMousePosition(event) {
			// Norm x and y values and prevent webgl coordinate interpolation
			this.mouse.x = (Math.floor(event.coordinate[0]) + 0.5) / this.data.canvas.width;
			this.mouse.y = (Math.floor(event.coordinate[1]) + 0.5) / this.data.canvas.height;

			if (this.mouse.x <= 1 && this.mouse.y <= 1 && this.mouse.x >= 0 && this.mouse.y >= 0) {
				this.renderHandler.render(this.mouse);
				//this.map.render();
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
		}

	}
}
</script>

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

.map {
	height: 100%;
	width: 100%;
	cursor: crosshair;
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
</style>
