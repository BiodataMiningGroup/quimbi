<template>
    <canvas id="histogram" width="40" height="256"></canvas>
</template>

<script>

    export default {
        props: [
            'histogram'
        ],
        data() {
            return {
                ctx: {},
            }
        },
        watch: {
            histogram() {
                    this.redrawHistogram();
                    console.log(this.histogram);
            }
        },
        mounted() {
        },
        methods: {
            redrawHistogram() {
                this.ctx = document.getElementById('histogram').getContext("2d");
                let width = 40;
                let height = 256;
                this.ctx.clearRect(0, 0, width, height);
                this.ctx.fillStyle = 'white';
                let maximum = Math.max.apply(0, this.histogram);
                let drawNumber = this.histogram.length;
                let widthCoefficient = width / maximum;
                while(drawNumber) {
                    this.ctx.fillRect(
                        width,
                        this.histogram.length - drawNumber--,
                        -1* this.histogram[drawNumber] * widthCoefficient,
                        1
                    );
                }
            },
        }
    }

</script>

<style scoped>
    #histogram {
    }

</style>

