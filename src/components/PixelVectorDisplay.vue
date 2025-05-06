<template>
<div class="intensity-list">
    <span v-show="hasHoveredFeature" class="hovered-feature" v-text="hoveredFeature"></span>
    <canvas ref="canvas"></canvas>
</div>
</template>

<script>
import {FIRE} from '../webgl/programs/colorMaps';

export default {
    props: {
        dataset: {
            required: true,
            type: Object,
        },
    },
    components: {
        //
    },
    data () {
        return {
            canvasSize: [0, 0],
            hasReference: false,
            hoveredFeature: null,
            xAxisHeight : 20,
        };
    },
    computed: {
        barWidth() {
            return this.canvasSize[0] / this.dataset.depth;
        },
        hasHoveredFeature() {
            return this.hoveredFeature !== null;
        },
    },
    methods: {
        updatePixelVector(pixelVector) {
            if (!this.hasReference) {
                this.pixelVector = pixelVector;
                this.draw();
            }
        },
        updateReferencePixelVector(pixelVector) {
            this.referencePixelVector = pixelVector;
            this.hasReference = pixelVector.length > 0;
            this.draw();
        },
        draw() {
            this.canvas.height = this.canvasSize[1] + this.xAxisHeight;
            this.canvas.width = this.canvasSize[0];

            if (this.hoveredFeature !== null) {
                // Bootstrap $gray-900.
                this.ctx.fillStyle = '#212529';
                this.ctx.fillRect(this.barWidth * this.hoveredFeature, 0, this.barWidth, this.canvas.height);
            }

            if (!this.hasReference) {
                this.drawWithoutReference();
            } else {
                this.drawWithoutReference();
            }
        },
        drawWithoutReference() {
            this.ctx.fillStyle = 'white';
            this.fillPath(0, 0 - this.xAxisHeight, this.canvas.width, this.canvas.height, this.pixelVector);
            this.drawXAxis(this.canvas.width, this.canvas.height - this.xAxisHeight, Math.floor(this.dataset.depth / 1000), this.dataset.depth);
        },
        drawWithReference() {
            let halfHeight = this.canvas.height / 2;
            this.ctx.fillStyle = 'white';
            this.fillPath(0, 0, this.canvas.width, halfHeight, this.pixelVector);
            // $primary color
            this.ctx.fillStyle = '#fc6600';
            this.fillPath(0, halfHeight, this.canvas.width, halfHeight, this.referencePixelVector);
        },
        fillPath(startX, startY, width, height, vector) {
            let minBarWidth = 1;
            let barWidth = this.barWidth;
            let ctx = this.ctx;

            for (var i = 0; i < vector.length; i++) {
                let barHeight = height * vector[i];
                let x = startX + i * barWidth;
                let actualBarWidth = barWidth >= minBarWidth ? barWidth : minBarWidth;

                ctx.fillRect(x, startY + height - barHeight, actualBarWidth, barHeight);
            }
        },
        updateCanvasSize() {
            this.canvasSize = [this.$el.clientWidth, this.$el.clientHeight];
        },
        updateHoveredFeature(event) {
            let rect = event.target.getBoundingClientRect();
            this.hoveredFeature = Math.floor(this.dataset.depth * (event.clientX - rect.left) / event.target.width);
        },
        resetHoveredFeature() {
            this.hoveredFeature = null;
        },
        drawXAxis(width, height, ticks, maxValue) {
            const ctx = this.ctx;
            const tickHeight = 4;
            const fontSize = 10;
            const startX = 0;
            const startY = 0;
            ctx.strokeStyle = '#aaa';
            ctx.fillStyle = '#aaa';
            ctx.lineWidth = 1;
            ctx.font = `${fontSize}px sans-serif`;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';

            ctx.beginPath();
            ctx.moveTo(startX, height);
            ctx.lineTo(startX + width, height);
            ctx.stroke();

            for (let i = 0; i <= ticks; i++) {
                const value = Math.round(i * maxValue / ticks);
                const x = startX + i * width / ticks;

                // Tick
                ctx.beginPath();
                ctx.moveTo(x, height);
                ctx.lineTo(x, height + tickHeight);
                ctx.stroke();

                // Label
                ctx.fillText(value.toString(), x, startY + height + tickHeight + 2);
            }
        }

    },
    watch: {
        canvasSize() {
            this.draw();
        },
        hoveredFeature(feature) {
            this.draw();
            this.$emit('hover', feature);
        },
    },
    created() {
        this.pixelVector = new Uint8Array([]);
        this.referencePixelVector = new Uint8Array([]);
    },
    mounted() {
        this.canvas = this.$refs.canvas;
        this.ctx = this.canvas.getContext('2d');
        window.addEventListener('resize', () => {
            this.$nextTick(this.updateCanvasSize)
        });
        this.$nextTick(this.updateCanvasSize);
        this.canvas.addEventListener('pointermove', this.updateHoveredFeature);
        this.canvas.addEventListener('pointerleave', this.resetHoveredFeature);
    },
};
</script>

<style lang="scss" scoped>
.intensity-list {
    height: 100%;

    .hovered-feature {
        position: absolute;
        top: 10px;
        left: 10px;
        color: $light;
        background-color: $gray-900;
        padding: $tooltip-padding-y $tooltip-padding-x;
        border-radius: 2px;
        pointer-events: none;
    }
}
</style>
