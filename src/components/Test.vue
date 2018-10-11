<template>
    <div class="counter">
            <p class="subtitle">
                {{ number }}
                <a href="#" @click.prevent="increment">Increment</a>
            </p>
    </div>
</template>

<script>
    export default {
        data() {
            return {
                number: 1
            }
        },
        methods: {
            increment () {
                this.number++
            }
        }
    }
</script>

<style scoped>
</style>
