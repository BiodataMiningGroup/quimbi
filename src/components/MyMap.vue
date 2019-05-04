<template>
<div ref="mymap" id="mymap-test" class="map"></div>
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
			mymap: undefined,
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
	},
	methods: {
		/**
		 * Created the openlayers mymap with the glmvilib canvas as layer source, adds hidden marker for
		 * pixel selection and calls updateView() to watch for mouse movement
		 */
		createMap() {
			let extent = [0, 0, this.data.canvas.width, this.data.canvas.height];
			let projection = new Projection({
				code: 'pixel-projection',
				units: 'pixels',
				extent: extent,
			});

			this.mymap = new Map({
				target: this.$refs.mymap,
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

			this.mymap.getView().fit(extent);
			//this.createMarker();
			//this.mymap.addLayer(this.markerLayer);

			this.updateView();
		},

		/**
		 * Adds event listener for map interaction
		 */
		updateView() {
			// Render image once to show something before the mouse is being moved
			//renders the map
			this.renderHandler.render(this.mouse);
			this.mymap.render();

			// Prevent image smoothing on mouse movement
			this.mymap.on('precompose', function(evt) {
				evt.context.imageSmoothingEnabled = false;
				evt.context.webkitImageSmoothingEnabled = false;
				evt.context.mozImageSmoothingEnabled = false;
				evt.context.msImageSmoothingEnabled = false;
			});

			// Add event listener for single click and mouse movement
			this.mymap.on('pointermove', this.notifyMouseMove);
			this.mymap.on('singleclick', this.notifyMouseClick);

		},
		notifyMouseMove(event) {
			this.$emit('MouseMove', event);
			console.log("test_move");
		},
		notifyMouseClick(event) {
			this.$emit('MouseClick', event);
			console.log("test_click");
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
