<template>
    <div id="colorscale-wrapper">
        <div id="wrapper-top"></div>
        <canvas id="colorscale" ref="canvas" width="30" height="256">
        </canvas>
        <div id="wrapper-bottom"></div>
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
        mounted() {
        },
        methods: {
            redrawScale() {
                this.scaleFactor = this.bounds[1] - this.bounds[0] || 1;
                this.ctx = document.getElementById('colorscale').getContext("2d");
                let width = 30;
                let height = 256;
                this.ctx.clearRect(0, 0, width, height);
                let drawnumber = height;
                let index = 0;
                while(drawnumber) {
                    this.ctx.fillStyle = "rgb(" + this.colormapvalues[index] + "," + this.colormapvalues[index + 1] +  "," + this.colormapvalues[index + 2] + ")";
                    this.ctx.fillRect(0, drawnumber, 30, 1);
                    index += 3;
                    drawnumber--;console.log();
                }
                // If no scaling is applied, set height op top wrapper to zero
                if(this.scaleFactor === 1) {
                    document.getElementById('wrapper-top').style = "height: 0px";
                } else {
                    document.getElementById('wrapper-top').style = "height: " +  (256 - Math.floor(this.bounds[1] * 256)) + "px";
                }
                document.getElementById('wrapper-bottom').style = "height: " +  Math.floor(this.bounds[0] * 256) + "px";
                document.getElementById('colorscale').style = "transform: scaleY(" + this.scaleFactor + "); transform-origin:top;";
            },
        }
    }

</script>


<style scoped>

    #colorscale {
        margin: 0;
        padding: 0;

    }

    #colorscale-wrapper {
        margin: 0;
        padding: 0;
        width: 30px;
        height: 256px;
        vertical-align: top;
        position: relative;
    }

    #wrapper-top {
        background-color: white;
        margin: 0;
        padding: 0;
        border-bottom: grey dotted 1px;
    }
    #wrapper-bottom {
        background-color:black;
        margin: 0;
        padding: 0;
        width: 30px;
        position: absolute;
        bottom: 0;
        border-top: #606060 dotted 1px;
    }
</style>