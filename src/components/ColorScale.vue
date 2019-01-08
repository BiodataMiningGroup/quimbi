<template>
    <div class="colorscale">
        <div class="wrapper-top" ref="wrapperTop"></div>
        <canvas class="canvas" ref="canvas"></canvas>
        <div class="wrapper-bottom" ref="wrapperBottom"></div>
    </div>

</template>

<script>

    export default {
        props: {
            colormapvalues: {
                type: Uint8Array,
                required: true
            },
            bounds: {
                type: Array,
                required: true,
            }
        }

        ,
        data() {
            return {
                scaleFactor: 1,
            }
        },
        methods: {
            /**
             * Draws the color scale with scale factor to the colorscale canvas and positions it correctly with css
             */
            redrawScale() {
                this.scaleFactor = this.bounds[1] - this.bounds[0] || 1;
                this.ctx = this.$refs.canvas.getContext("2d");
                let height = 0;
                // If no scaling is applied, set height op top wrapper to zero
                if (this.scaleFactor === 1 || this.bounds[1] === 1) {
                    this.$refs.wrapperTop.style = "display: none;";
                } else {
                    height = (1 - this.bounds[1]) * 100;
                    this.$refs.wrapperTop.style = "height: " + height + "%";
                }

                if (this.scaleFactor === 1 || this.bounds[0] === 0) {
                    this.$refs.wrapperBottom.style = "display: none;";
                } else {
                    height = this.bounds[0] * 100;
                    this.$refs.wrapperBottom.style = "height: " + height + "%";
                }
                height = this.scaleFactor * 100;
                this.$refs.canvas.style = "height: " + height + "%;";
            },

            initScale() {
                let height = this.colormapvalues.length / 3;
                this.ctx = this.$refs.canvas.getContext("2d");
                this.$refs.canvas.width = 1;
                this.$refs.canvas.height = height;
                let index = 0;
                // Draw colored lines
                for (let i = height - 1; i >= 0; i--) {
                    index = i * 3;
                    this.ctx.fillStyle = "rgb(" + this.colormapvalues[index] + "," + this.colormapvalues[index + 1] + "," + this.colormapvalues[index + 2] + ")";
                    this.ctx.fillRect(0, height - (i + 1), 1, 1);
                }
            }
        },
        mounted() {
            this.initScale();
        },
    }

</script>


<style scoped>
    .colorscale {
        display: flex;
        flex-direction: column;
        width: 30px;
        height: 256px;
        position: relative;
    }

    .canvas {
        width: 100%;
    }

    .wrapper-top {
        background-color: white;
        border-bottom: black dotted 1px;
    }

    .wrapper-bottom {
        background-color: black;
        border-top: white dotted 1px;
    }
</style>
