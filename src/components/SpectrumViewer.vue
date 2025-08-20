<template>
    <div class="intensity-list">
        <div ref="tooltip" v-show="hasHoveredFeature" class="hovered-feature" :style="{transform: `translate(${mouseX}px, ${mouseY}px)`, position: 'absolute'}">
            <div>m/z: {{ hoveredMZ }}</div>
            <div>Intensität: {{ hoveredIntensity }}</div>
        </div>
        <canvas ref="canvas"></canvas>
    </div>
</template>

<script>
import zoom from '../logic/zoom.js';
import drag from '../logic/drag.js';
import spectrumAreas from '../logic/spectrumAreas.js';

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
    mixins: [zoom, drag, spectrumAreas],
    data () {
        return {
            canvasSize: [0, 0],
            hasReference: false,
            hoveredFeature: null,
            hoveredMZ: null,
            hoveredIntensity: null,
            xAxisHeight : 20,
            yAxisHeight : 20,
            leftPadding : 55,
            rightPadding : 25,
            mouseX: 0,
            mouseY: 0,
            viewStart: null,
            viewEnd: null,
        };
    },
    computed: {
        barWidth() {
            const drawWidth = this.canvasSize[0] - this.leftPadding - this.rightPadding;
            return drawWidth / (this.viewEnd - this.viewStart);
        },
        actualBarWidth() {
            const minBarWidth = 1;
            return this.barWidth >= minBarWidth ? this.barWidth : minBarWidth;
        },
        hasHoveredFeature() {
            return this.hoveredFeature !== null;
        },
    },
    methods: {
        updatePixelVector(pixelVector) {
            this.pixelVector = pixelVector;
            this.resetZoom()
            this.draw();
        },
        draw() {
            this.canvas.height = this.canvasSize[1];
            this.canvas.width = this.canvasSize[0];

            if (this.hoveredFeature !== null) {
                // Bootstrap $gray-900.
                this.ctx.fillStyle = '#212529';
                const x = this.leftPadding + this.barWidth * (this.hoveredFeature - this.viewStart);
                this.ctx.fillRect(x, 0, this.actualBarWidth, this.canvas.height);
            }

            this.drawTempSpectrumSelection();
            this.drawWithoutReference();
            this.drawActiveAreas();
        },
        drawWithoutReference() {
            this.ctx.fillStyle = 'white';
            let drawHeight = this.canvas.height - this.xAxisHeight - this.yAxisHeight;
            let drawWidth = this.canvas.width - this.leftPadding - this.rightPadding;
            let startX = this.leftPadding;
            let startY = this.yAxisHeight;
            let viewEnd = this.viewEnd;
            let viewStart = this.viewStart;
            const visibleVector = this.pixelVector.slice(this.viewStart, this.viewEnd);

            this.fillPath(startX, startY, drawHeight, visibleVector);
            this.drawXAxis(startX, startY, drawWidth, drawHeight, 10, viewStart, viewEnd);
            this.drawYAxis(startX, startY, drawHeight, 4)
        },
        fillPath(startX, startY, height, vector) {
            let ctx = this.ctx;
            let barWidth = this.barWidth;
            let actualBarWidth = this.actualBarWidth;

            for (var i = 0; i < vector.length; i++) {
                let barHeight = height * vector[i] * this.yZoom;
                let actualHeight = Math.min(barHeight, height);

                let x = startX + i * barWidth;
                let y = startY + height - actualHeight;

                ctx.fillRect(x, y, actualBarWidth, actualHeight);

                // Marker (Kreis)
                if (barHeight > height) {
                    ctx.beginPath();
                    ctx.arc(x + actualBarWidth / 2, y - 10, 5, 0, 2 * Math.PI)
                    ctx.fill();
                    ctx.closePath();
                }
            }
        },
        updateCanvasSize() {
            this.canvasSize = [this.$el.clientWidth, this.$el.clientHeight];
        },
        updateHoveredFeature(event) {
            let rect = event.target.getBoundingClientRect();

            this.mouseX = event.clientX - rect.left + 10;
            this.mouseY = event.clientY - rect.top + 10;

            const tooltip = this.$refs.tooltip?.getBoundingClientRect();
            const tooltipWidth = tooltip?.width;
            const tooltipHeight = tooltip?.height;

            if (this.mouseX + tooltipWidth > this.canvasSize[0]) {
                this.mouseX = this.mouseX - tooltipWidth - 30;
            }
            if (this.mouseY + tooltipHeight > this.canvasSize[1]) {
                this.mouseY = this.mouseY - tooltipHeight - 20;
            }

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
            const index = Math.floor(this.viewStart + ratio * (this.viewEnd - this.viewStart));
            this.hoveredFeature = index;
            this.hoveredMZ = this.dataset.channels[index];
            if (this.pixelVector[index] === undefined) {
                this.hoveredIntensity = null;
            } else {
                this.hoveredIntensity = Number(this.pixelVector[index].toPrecision(2));
            }
        },
        resetHoveredFeature() {
            this.hoveredFeature = null;
        },
        drawXAxis(startX, startY, width, height, ticks, viewStart, viewEnd) {
            const ctx = this.ctx;
            const tickHeight = 4;
            const y = startY + height;
            ctx.strokeStyle = '#aaa';
            ctx.fillStyle = '#aaa';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';

            ctx.beginPath();
            ctx.moveTo(startX, y);
            ctx.lineTo(startX + width, y);
            ctx.stroke();

            const range = Math.max(1, viewEnd - viewStart);
            for (let i = 0; i <= ticks; i++) {
                let index = Math.round(viewStart + (i * range / ticks));
                index = Math.max(viewStart, Math.min(viewEnd - 1, index));
                const x = Math.round(startX + (index - viewStart + 0.5) * this.barWidth);

                // Tick
                ctx.beginPath();
                ctx.moveTo(x, y);
                ctx.lineTo(x, y + tickHeight);
                ctx.stroke();

                // Label
                const label = this.dataset?.channels?.[index];
                if (label !== undefined) {
                    ctx.fillText(Math.round(label).toString(), x, y + tickHeight + 2);
                }
            }
        },
        drawYAxis(startX, startY, height, ticks) {
            const ctx = this.ctx;
            const tickWidth = 4;
            ctx.strokeStyle = '#aaa';
            ctx.fillStyle = '#aaa';
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

                ctx.fillText(label.toPrecision(2), startX - tickWidth - 2, y);
            }
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
        dataset(data) {
            if (data) {
                this.viewStart = 0;
                this.viewEnd = data.depth;
            }
        }
    },
    created() {
        this.pixelVector = new Uint8Array([]);
    },
    mounted() {
        this.canvas = this.$refs.canvas;
        this.ctx = this.canvas.getContext('2d');
        this.viewStart = 0;
        this.viewEnd = this.dataset.depth;

        window.addEventListener('resize', () => {
            this.$nextTick(this.updateCanvasSize)
        });
        this.$nextTick(this.updateCanvasSize);
        this.canvas.addEventListener('pointermove', this.updateHoveredFeature);
        this.canvas.addEventListener('pointerleave', this.resetHoveredFeature);
        this.canvas.addEventListener('wheel', this.handleWheelScroll);

        this.canvas.addEventListener('pointerdown', this.handlePointerDown);
        this.canvas.addEventListener('pointermove', this.handlePointerDrag);
        this.canvas.addEventListener('pointerup', this.handlePointerUp);
        this.canvas.addEventListener('pointerleave', this.handlePointerUp);

        this.canvas.addEventListener('click', this.handleClick);
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
