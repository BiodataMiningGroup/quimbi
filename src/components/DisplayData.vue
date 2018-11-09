<template>
    <section class="section">
        <div class="container">
            <h1 class=" has-text-centered">Display</h1>
            <div id="map" class="map"></div>
        </div>
    </section>
</template>

<script>
    import Map from '../../node_modules/ol/Map';
    import View from '../../node_modules/ol/View';
    import ImageLayer from 'node_modules/ol/layer/Image';
    import ImageSource from '../utils/ImageCanvas.js';
    import Projection from 'node_modules/ol/proj/Projection';
    import {getCenter} from 'node_modules/ol/extent';

    import ShaderHandler from '../utils/ShaderHandler.js';


    export default {
        props: [
            'initData'
        ],
        data() {
            return {
                data: this.initData,
                map: undefined,
                shaderHandler: undefined,
                timeStampBefore: 0,
                mouse: {
                    x: 0,
                    y: 0
                }
            }
        },
        created() {
            // Initialize shader
            this.shaderHandler = new ShaderHandler(this.data);
            this.shaderHandler.createShader();
        },
        mounted() {
            // Create map view after html template has loaded
            this.createMap();
            // Todo remove me
            //window.glmvilib.finish();
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
                    view: new View({
                        projection: projection,
                        center: getCenter(extent),
                        // Initially, display canvas at original resolution (100%).
                        resolution: 1,
                        zoomFactor: 2,
                        // Allow a maximum of 4x magnification.
                        minResolution: 0.25,
                        // Restrict movement.
                        extent: extent,
                    }),
                });

                // Render and update image on mouse movement
                this.updateView();

            },
            updateView() {
                // Render image to show it before user moves the mouse
                this.shaderHandler.render(this.mouse);
                this.map.render();

                // Prevent image smoothing on mouse movement
                this.map.on('precompose', function(evt) {
                    evt.context.imageSmoothingEnabled = false;
                    evt.context.webkitImageSmoothingEnabled = false;
                    evt.context.mozImageSmoothingEnabled = false;
                    evt.context.msImageSmoothingEnabled = false;
                });

                // Listen for mouse movement, update mouse coordinates and render the image
                this.map.on('pointermove', (event) => {
                    // Update if there is a certain time interval (in ms) between movements
                    // Todo Maybe change interval for larger datasets, rendering is laggy with the largest set
                    if (event.originalEvent.timeStamp - this.timeStampBefore > 50) {
                        //console.log(event.coordinate);
                        this.mouse.x = event.coordinate[0] / this.data.canvas.width;
                        this.mouse.y = event.coordinate[1] / this.data.canvas.height;

                        if (this.mouse.x <= 1 && this.mouse.y <= 1 && this.mouse.x >= 0 && this.mouse.y >= 0) {
                            this.shaderHandler.render(this.mouse);
                            this.map.render();
                        }
                        this.timeStampBefore = event.originalEvent.timeStamp;
                    }
                });
            }
        },
    }
</script>

<style scoped>
    .map {
        height: 400px;
        width: 100%;
        background-color: grey;
    }
</style>