<template>
    <div class="intensity-list">
        <div v-show="hasHoveredFeature" class="hovered-feature" :style="{left: (mouseX + 10) + 'px',top: (mouseY + 10) + 'px',position: 'absolute'}">
            <div>Feature: {{ hoveredFeature }}</div>
            <div>m/z: {{ hoveredMZ }}</div>
            <div>Intensity: {{ hoveredIntensity }}</div>
        </div>
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
            hoveredMZ: null,
            hoveredIntensity: null,
            xAxisHeight : 20,
            yAxisHeight : 20,
            leftPadding : 30,
            rightPadding : 15,
            mouseX: 0,
            mouseY: 0,
            viewStart: null,
            viewEnd: null,
            zoomFactor: 2,
            yZoom: 1,
            yZoomFactor: 1.1,
        };
    },
    computed: {
        barWidth() {
            return this.canvasSize[0] / (this.viewEnd - this.viewStart);
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
            let viewEnd = this.viewEnd;
            let viewStart = this.viewStart;

            const viewRange = this.viewEnd - this.viewStart;
            const visibleVector = this.pixelVector.slice(this.viewStart, this.viewEnd);


            this.fillPath(startX, startY, drawWidth, drawHeight, visibleVector);
            this.drawXAxis(startX, startY, drawWidth, drawHeight, 10, viewStart, viewEnd);
            this.drawYAxis(startX, startY, drawWidth,drawHeight, 4)
        },
        fillPath(startX, startY, width, height, vector) {
            let minBarWidth = 1;
            let barWidth = this.barWidth;
            let ctx = this.ctx;

            for (var i = 0; i < vector.length; i++) {
                let barHeight = height * vector[i] * this.yZoom;
                barHeight = Math.min(barHeight, height);
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
            //this.hoveredFeature = Math.floor(this.dataset.depth * (event.clientX - rect.left) / event.target.width);

            this.mouseX = event.clientX - rect.left;
            this.mouseY = event.clientY - rect.top;

            const relativeX = event.clientX - rect.left;
            const contentWidth = event.target.width - this.leftPadding - this.rightPadding;
            const xInContent = relativeX - this.leftPadding;

            if (xInContent < 0 || xInContent > contentWidth) {
                this.hoveredFeature = null;
                this.hoveredMZ = null;
                this.hoveredIntensity = null;
                return;
            }

            const ratio = xInContent / contentWidth;
            this.hoveredFeature = Math.floor(this.dataset.depth * ratio);
            this.hoveredMZ = this.dataset.channels[this.hoveredFeature]
            this.hoveredIntensity = this.pixelVector[this.hoveredFeature];
        },
        resetHoveredFeature() {
            this.hoveredFeature = null;
        },
        drawXAxis(startX, startY, width, height, ticks, viewStart, viewEnd) {
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
                const index = Math.round(viewStart + (i * (viewEnd - viewStart) / ticks));
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
                //console.log(i + ". X - label: " + label)
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

            const maxYValue = 1 / this.yZoom;

            for (let i = 0; i <= ticks; i++) {
                const label = maxYValue * (ticks - i) / ticks;
                const y = startY + i * height / ticks;

                // Tick
                ctx.beginPath();
                ctx.moveTo(startX, y);
                ctx.lineTo(startX - tickWidth, y);
                ctx.stroke();

                //console.log(i + ". Y - label: " + label)
                ctx.fillText(label.toFixed(2), startX - tickWidth - 2, y);
            }
        },
        handleWheelScroll(event) {
            event.preventDefault();

            const rect = this.canvas.getBoundingClientRect();
            const relativeX = event.clientX - rect.left - this.leftPadding;
            const contentWidth = this.canvas.width - this.leftPadding - this.rightPadding;

            const ratio = relativeX / contentWidth;
            //console.log("ratio" + ratio)

            if (event.ctrlKey) {
                console.log("event.ctrlKey" + event.ctrlKey)
                // Y-Achse zoomen
                if (event.deltaY < 0) {
                    this.yZoom *= this.yZoomFactor;
                } else {
                    this.yZoom /= this.yZoomFactor;
                }
                this.yZoom = Math.max(0.1, Math.min(this.yZoom, 10));
                this.draw();
            } else {
                // X-Achse zoomen
                if (event.deltaY < 0) {
                    this.zoomIn(ratio);
                } else {
                    this.zoomOut(ratio);
                }
            }
        },
        zoomIn(ratio) {
            const range = this.viewEnd - this.viewStart;
            const newRange = Math.max(10, Math.floor(range / this.zoomFactor));
            let newStart;
            let newEnd;

            if (ratio < 0.05) {
                // Maus befindet sich ganz links
                newStart = this.viewStart;
                newEnd = this.viewStart + newRange;
            } else if (ratio > 0.95) {
                // Maus befindet sich ganz rechts
                newEnd = this.viewEnd;
                newStart = this.viewEnd - newRange;
            } else {
                // normaler Zoom
                const focus = this.viewStart + range * ratio;
                newStart = Math.floor(focus - newRange * ratio);
                newEnd = Math.floor(focus + newRange * (1 - ratio));
            }

            newStart = Math.max(0, newStart);
            newEnd = Math.min(this.dataset.depth, newEnd);

            if (newEnd - newStart < 10) return;
            this.viewStart = newStart;
            this.viewEnd = newEnd;
            this.draw();
        },
        zoomOut(ratio) {
            const range = this.viewEnd - this.viewStart;
            const newRange = Math.min(this.dataset.depth, Math.ceil(range * this.zoomFactor));
            let newStart;
            let newEnd;

            if (ratio < 0.05) {
                // Maus befindet sich ganz links
                newStart = this.viewStart;
                newEnd = this.viewStart + newRange;
            } else if (ratio > 0.95) {
                // Maus befindet sich ganz rechts
                newEnd = this.viewEnd;
                newStart = this.viewEnd - newRange;
            } else {
                // normaler Zoom
                const focus = this.viewStart + range * ratio;
                newStart = Math.floor(focus - newRange * ratio);
                newEnd = Math.floor(focus + newRange * (1 - ratio));
            }

            newStart = Math.max(0, newStart);
            newEnd = Math.min(this.dataset.depth, newEnd);

            this.viewStart = newStart;
            this.viewEnd = newEnd;
            this.draw();
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
        dataset(data) {
            if (data) {
                this.viewStart = 0;
                this.viewEnd = data.depth;
            }
        }
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
        this.canvas.addEventListener('wheel', this.handleWheelScroll);

        //console.log('Channels:', this.dataset.channels);
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
