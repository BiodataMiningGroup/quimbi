<template>
<div id="mymap-test" class="map">
	<p>Test</p>
</div>
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

export default {
	props: [
		'data'
	],
	data() {
		return {
			mymap: undefined
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
			this.mymap.render();
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
