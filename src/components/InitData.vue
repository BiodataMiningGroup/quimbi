<template>
    <section class="section">
        <div class="container">
            <h1 class="title">
                Quimbi
            </h1>
            <label>
                <button class="button" @click="parseData">Load Data</button>
            </label>
            <a href="/data/small-stacked-max.txt">data</a>
            <div id="data">
                {{ data }}
            </div>
        </div>
    </section>
</template>

<script>
        import axios from 'axios';
    export default {
        data() {
            return {
                filePath: 'data/small-stacked-max.txt',
                data: ''
            }
        },
        methods: {
            parseData() {
                axios.get(this.filePath).then(
                    response => (this.data = response)
                );
                console.log(this.data);
            }
        }
    }
</script>

<style>

</style>