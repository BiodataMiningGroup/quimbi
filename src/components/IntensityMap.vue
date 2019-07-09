<template>
<div ref="intensitymap" id="intensitymap" class="map"></div>
</template>

<script>
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
			}
		}
	},
	mounted() {
		// Create map view after html template has loaded
		this.createMap();
		this.$emit("setMap", this.intensitymap);
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
				target: this.$refs.intensitymap,
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

			this.intensitymap.getView().fit(extent);
			//this.createMarker();
			//this.intensitymap.addLayer(this.markerLayer);

			this.updateView();
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
				evt.context.webkitImageSmoothingEnabled = false;
				evt.context.mozImageSmoothingEnabled = false;
				evt.context.msImageSmoothingEnabled = false;
			});

			// Add event listener for single click and mouse movement
			this.intensitymap.on('pointermove', this.notifyMouseMove);
			this.intensitymap.on('singleclick', this.notifyMouseClick);

		},
		notifyMouseMove(event) {
			this.$emit('MouseMove', event);
		},
		notifyMouseClick(event) {
			this.$emit('mouseclick', event);
		}
	}
}
</script>
<style scoped>
.map {
	height: 100%;
	width: 100%;
	cursor: crosshair;
}
</style>
