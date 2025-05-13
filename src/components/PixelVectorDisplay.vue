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
            yAxisHeight : 20,
            leftPadding : 30,
            rightPadding : 15,
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
            this.canvas.height = this.canvasSize[1];
            this.canvas.width = this.canvasSize[0];

            if (this.hoveredFeature !== null) {
                // Bootstrap $gray-900.
                this.ctx.fillStyle = '#212529';
                this.ctx.fillRect(this.barWidth * this.hoveredFeature, 0, this.barWidth, this.canvas.height);
            }

            this.drawWithoutReference();
        },
        drawWithoutReference() {
            this.ctx.fillStyle = 'white';
            let drawHeight = this.canvas.height - this.xAxisHeight - this.yAxisHeight;
            let drawWidth = this.canvas.width - this.leftPadding - this.rightPadding;
            let startX = this.leftPadding;
            let startY = this.yAxisHeight;
            this.fillPath(startX, startY, drawWidth, drawHeight, this.pixelVector);
            this.drawXAxis(startX, startY, drawWidth, drawHeight, 10, this.dataset.depth);
            this.drawYAxis(startX, startY, drawWidth,drawHeight, 4)
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
        drawXAxis(startX, startY, width, height, ticks, maxValue) {
            const ctx = this.ctx;
            const tickHeight = 4;
            const fontSize = 10;
            const y = startY + height;
            ctx.strokeStyle = '#aaa';
            ctx.fillStyle = '#aaa';
            ctx.lineWidth = 1;
            ctx.font = `${fontSize}px sans-serif`;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';

            ctx.beginPath();
            ctx.moveTo(startX, y);
            ctx.lineTo(startX + width, y);
            ctx.stroke();

            for (let i = 0; i <= ticks; i++) {
                const index = Math.round(i * maxValue / ticks);
                const x = startX + i * width / ticks;

                // Tick
                ctx.beginPath();
                ctx.moveTo(x, y);
                ctx.lineTo(x, y + tickHeight);
                ctx.stroke();

                // Label
                let label = Math.round(this.dataset.channels[index]);
                if (i !== 0) {
                    label = Math.round(this.dataset.channels[index - 1]);
                }
                console.log(i + ". X - label: " + label)
                ctx.fillText(label.toString(), x, y + tickHeight + 2);
            }
        },
        drawYAxis(startX, startY, width, height, ticks) {
            const ctx = this.ctx;
            const tickWidth = 4;
            const fontSize = 10;

            ctx.strokeStyle = '#aaa';
            ctx.fillStyle = '#aaa';
            ctx.lineWidth = 1;
            ctx.font = `${fontSize}px sans-serif`;
            ctx.textAlign = 'right';
            ctx.textBaseline = 'middle';

            ctx.beginPath();
            ctx.moveTo(startX, startY);
            ctx.lineTo(startX, startY + height);
            ctx.stroke();

            for (let i = 0; i <= ticks; i++) {
                const label = Math.round(((ticks - i) / ticks) * 100) / 100;
                const y = startY + i * height / ticks;

                // Tick
                ctx.beginPath();
                ctx.moveTo(startX, y);
                ctx.lineTo(startX - tickWidth, y);
                ctx.stroke();

                console.log(i + ". Y - label: " + label)
                ctx.fillText(label.toString(), startX - tickWidth - 2, y);
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
        console.log('Channels:', this.dataset.channels);
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
