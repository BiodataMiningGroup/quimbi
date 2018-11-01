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
    import TileLayer from '../../node_modules/ol/layer/Tile';
    import XYZ from 'node_modules/ol/source/XYZ';
    import OSM from '../../node_modules/ol/source/OSM';

    export default {
        data() {
            return {
                data: this.$parent.$data.data,
                // Todo replace with property

                // Webgl inspector for chrome
            }
        },
        mounted() {
            this.createMap()
        },
        methods: {
            createMap() {
                let map = new Map({
                    view: new View({
                        center: [0, 0],
                        zoom: 2
                    }),
                    layers: [
                        new TileLayer({
                            source: new OSM()
                        })
                    ],
                    target: 'map'
                });
                console.log(map.getTargetElement());
            }
        }
    }

</script>

<style scoped>
    .map {
        height: 400px;
        width: 90%;
    }
</style>