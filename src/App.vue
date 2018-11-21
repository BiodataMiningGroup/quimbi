<template>
    <div id="app">
        <InitData v-if="showInitData" @finish="onFinishedInit"></InitData>
        <DisplayData v-if="showDisplayData" :initData="data"></DisplayData>
    </div>
</template>

<script>
    import InitData from './components/InitData.vue'
    import DisplayData from './components/DisplayData.vue'


    export default {
        name: 'app',
        components: {
            InitData,
            DisplayData,
        },
        data() {
            return {
                data: {},
                showInitData: true,
                showDisplayData: false
            }
        },
        methods: {
            // Gets called when data was initialized by the InitData component
            onFinishedInit(data) {
                this.showInitData = false;
                this.showDisplayData = true;
                this.data = data;
            }
        }
    }
</script>

<style>
    @import '~bulma/css/bulma.min.css';
    @import '/src/assets/fontawesome-free-5.5.0-web/css/all.css';
</style>