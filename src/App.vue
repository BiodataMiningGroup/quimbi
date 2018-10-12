<template>
    <div id="app">
        <InitData></InitData>
    </div>
</template>

<script>
    import InitData from './components/InitData.vue'


    export default {
        name: 'app',
        components: {
            InitData,
        }
    }
</script>

<style>
    @import '~bulma/css/bulma.min.css';
</style>