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
    import MousePosition from 'ol/control/MousePosition';

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
                coord: undefined,
                timeStampBefore: 0,
                mouse: {
                    x: 0,
                    y: 0
                }
            }
        },
        mounted() {
            //let angleDist = new AngleDist();
            //console.log(angleDist);
            this.shaderHandler = new ShaderHandler();
            this.shaderHandler.createShader();
            this.shaderHandler.getActive();
            //this.shaderHandler.render();
            this.createMap();
            // Todo remove me
            window.glmvilib.finish();
        },
        methods: {
            createMap() {
                // Todo: Contect 2d or webgl?
                let ctx = this.data.canvas.getContext('2d');

                /*let tmpCanvas = document.createElement('canvas');
                tmpCanvas.height = 100;
                tmpCanvas.width = 100;
                let ctx = tmpCanvas.getContext('2d');
                ctx.fillStyle = 'green';
                ctx.fillRect(0, 0, 100, 100);
                */

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
                                canvas: ctx,
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

                // Listen for mouse movement and pdate mouse coordinates
                this.map.on('pointermove', (event) => {
                    // Update if there is a certain time interval (in ms) between movements
                    if(event.originalEvent.timeStamp - this.timeStampBefore > 300) {
                        console.log(event.coordinate);
                        this.mouse.x = event.coordinate[0];
                        this.mouse.y = event.coordinate[1];

                        this.timeStampBefore = event.originalEvent.timeStamp;
                    }

                });

            },
        }


    }

</script>

<style scoped>
    .map {
        height: 400px;
        width: 100%;
        background-color: grey;
    }
</style>