<template>
    <section class="section">
        <div class="container">
            <h1 class="title">
                Quimbi
            </h1>
            <label class="text-reader">
                <input type="file" id="file">
            </label>
            <label for=><button class="button" @click="parseData">Load Data</button></label>



        </div>
    </section>
</template>

<script>
    export default {
        data() {
            return {
                file: './data/small-stacked-max.txt'
            }
        },
        methods: {
            parseData() {


            }

        }
    }
</script>

<style>

</style>