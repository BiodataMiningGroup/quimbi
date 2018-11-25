<template>
    <canvas id="colorscale" width="30" height="256"></canvas>
</template>

<script>

    export default {
        props: [
            'bounds',
            'colormapvalues'
        ],
        data() {
            return {
            }
        },
        mounted() {
        },
        methods: {
            redrawScale() {
                this.ctx = document.getElementById('colorscale').getContext("2d");
                console.log(this.colormapvalues);
                let width = 30;
                let height = 256;
                let drawnumber = height;
                let index = 0;
                this.ctx.clearRect(0, 0, width, height);
                while(drawnumber) {
                    this.ctx.fillStyle = "rgb(" + this.colormapvalues[index] + "," + this.colormapvalues[index + 1] +  "," + this.colormapvalues[index + 2] + ")";
                    this.ctx.fillRect(0, drawnumber, 30, 1);
                    index += 3;
                    drawnumber--;
                }
            }

        }

    }

</script>


<style scoped>

    #colorscale {
    }

</style>