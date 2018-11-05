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
    import AngleDist from "../utils/programs/angledist";


    export default {
        props: [
            'initData'
        ],
        data() {
            return {
                data: this.initData,
                shaderHandler: undefined,
                mousePosition: undefined
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
                /*
                this.data.canvas.height = 100;
                this.data.canvas.width = 100;
                console.log(this.data.canvas.getContext("webgl"));
                let ctx = this.data.canvas.getContext('webgl');
                */
                let tmpCanvas = document.createElement('canvas');
                tmpCanvas.height = 100;
                tmpCanvas.width = 100;
                let ctx = tmpCanvas.getContext('2d');
                ctx.fillStyle = 'green';
                ctx.fillRect(0, 0, 100, 100);

                let extent = [0, 0, tmpCanvas.width, tmpCanvas.height];
                let projection = new Projection({
                    code: 'pixel-projection',
                    units: 'pixels',
                    extent: extent,

                });
                const map = new Map({
                    target: 'map',
                    layers: [
                        new ImageLayer({
                            source: new ImageSource({
                                canvas: tmpCanvas,
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
                map.on('pointermove', function (event) {
                    console.log = event.coordinate;
                });
            }
        }
    }

</script>

<style scoped>
    .map {
        height: 400px;
        width: 100%;
    }
</style>