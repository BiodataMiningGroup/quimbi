<template>
    <div id="app">
        <section class="section">
            <div class="container">
                <h1 class="title">
                    Hello World
                </h1>
                <p class="subtitle">
                    My first website with <strong>Bulma</strong>!
                </p>


            </div>
        </section>
    </div>
</template>

<script>
    import Test from './components/test.vue'

    export default {
        name: 'app',
        components: {
            Test
        }
    }
</script>

<style>
    @import '~bulma/css/bulma.min.css';
</style>