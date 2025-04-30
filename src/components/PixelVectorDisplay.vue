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
            this.pixelVector = pixelVector;
            this.draw();
        },
        updateReferencePixelVector(pixelVector) {
            this.referencePixelVector = pixelVector;
            this.hasReference = pixelVector.length > 0;
            this.draw();
        },
        draw() {
            this.canvas.width = this.canvasSize[0];
            this.canvas.height = this.canvasSize[1];

            if (this.hoveredFeature !== null) {
                // Bootstrap $gray-900.
                this.ctx.fillStyle = '#212529';
                this.ctx.fillRect(this.barWidth * this.hoveredFeature, 0, this.barWidth, this.canvas.height);
            }

            if (this.hasReference) {
                this.drawWithReference();
            } else {
                this.drawWithoutReference();
            }
        },
        drawWithoutReference() {
            this.ctx.fillStyle = 'white';
            this.fillPath(0, 0, this.canvas.width, this.canvas.height, this.pixelVector, -1);
        },
        drawWithReference() {
            let halfHeight = this.canvas.height / 2;
            this.ctx.fillStyle = 'white';
            this.fillPath(0, 0, this.canvas.width, halfHeight, this.pixelVector, -1);
            // $primary color
            this.ctx.fillStyle = '#fc6600';
            this.fillPath(0, halfHeight, this.canvas.width, halfHeight, this.referencePixelVector, 1);
        },
        fillPath(startX, startY, width, height, vector, factor) {
            let barWidth = this.barWidth;
            let barHeight = 0;
            let ctx = this.ctx;
            ctx.beginPath();
            ctx.moveTo(startX, startY + height);
            for (var i = 0; i < vector.length; i++) {
                barHeight = height * vector[i];
                ctx.lineTo(startX + i * barWidth, startY + height - barHeight);
                ctx.lineTo(startX + (i + 1) * barWidth, startY + height - barHeight);
            }
            ctx.lineTo(startX + width, startY + height);
            ctx.lineTo(startX, startY + height);
            ctx.fill();
        },
        updateCanvasSize() {
            this.canvasSize = [this.$el.clientWidth, this.$el.clientHeight];
        },
        updateHoveredFeature(event) {
            let rect = event.target.getBoundingClientRect();
            this.hoveredFeature = Math.floor(this.dataset.depth * (event.clientY - rect.top) / event.target.height);
        },
        resetHoveredFeature() {
            this.hoveredFeature = null;
        },
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
