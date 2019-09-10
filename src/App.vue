<template>
    <div id="app">
        <InitData v-if="showInitData" @InitedRenderer="onInitedRenderer" @finish="onFinishedInit"></InitData>
        <DisplayData v-if="showDisplayData" :initData="data" :renderHandler="renderHandler"></DisplayData>
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
                renderHandler: undefined,
                data: {},
                showInitData: true,
                showDisplayData: false
            }
        },
        methods: {
            onInitedRenderer(renderHandler){
              this.renderHandler = renderHandler;
            },

            /**
             * Gets called when data was initialized by the InitData component
             * @param data
             */
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
    @import '~@fortawesome/fontawesome-free/css/all.css';

    #app {
        height: 100%;
    }
</style>
