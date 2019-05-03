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
			this.createMarker();
			this.mymap.addLayer(this.markerLayer);

			this.updateView();
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
		},
		updateView() {
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
