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
            leftPadding : 55,
            rightPadding : 25,
            mouseX: 0,
            mouseY: 0,
            viewStart: null,
            viewEnd: null,
            zoomFactor: 2,
            yZoom: 1,
            yZoomFactor: 1.1,
            isDragging: false,
            dragStartX: 0,
            dragStartViewStart: 0,
            allAreas: null,
            hoveredAreaIndex: null,
            spectrumAreaStart: null,
            spectrumSelectionMode: false,
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

            for (let i = 0; i <= ticks; i++) {
                const index = Math.round(viewStart + (i * (viewEnd - viewStart) / ticks));
                if (isNaN(index)) continue;
                const x = startX + i * width / ticks + this.barWidth / 2;

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
                ctx.fillText(label.toString(), x, y + tickHeight + 2);
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
        handleWheelScroll(event) {
            event.preventDefault();

            const rect = this.canvas.getBoundingClientRect();
            const relativeX = event.clientX - rect.left - this.leftPadding;
            const contentWidth = this.canvas.width - this.leftPadding - this.rightPadding;

            const ratio = relativeX / contentWidth;

            if (event.ctrlKey) {
                // Y-Achse zoomen
                if (event.deltaY < 0) {
                    this.yZoom *= this.yZoomFactor;
                } else {
                    this.yZoom /= this.yZoomFactor;
                }
                if (this.yZoom < 1) {
                    this.yZoom = 1;
                }
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
            this.updateYZoomToVisibleMax();
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
            this.updateYZoomToVisibleMax();
            this.draw();
        },
        updateYZoomToVisibleMax() {
            const visibleVector = this.pixelVector.slice(this.viewStart, this.viewEnd);
            const maxValue = Math.max(...visibleVector);

            if (maxValue > 0) {
                this.yZoom = 1 / maxValue;
            } else {
                this.yZoom = 1;
            }
        },
        resetZoom() {
            this.yZoom = 1;
            this.viewStart = 0;
            this.viewEnd = this.dataset.depth;
            this.draw()
        },
        handlePointerDown(event) {
            if (this.spectrumSelectionMode) return;
            const rect = this.canvas.getBoundingClientRect();
            const x = event.clientX - rect.left - this.leftPadding;
            this.isDragging = true;
            this.dragStartX = x;
            this.dragStartViewStart = this.viewStart;
        },
        handlePointerUp() {
            this.isDragging = false;
        },
        handlePointerDrag(event) {
            if (!this.isDragging) return;

            const rect = this.canvas.getBoundingClientRect();
            const x = event.clientX - rect.left - this.leftPadding;
            const diffX = x - this.dragStartX;
            const dataPerPixel = (this.viewEnd - this.viewStart) / (this.canvasSize[0] - this.leftPadding - this.rightPadding);
            const moveData = Math.round(diffX * dataPerPixel);


            let newStart = this.dragStartViewStart - moveData;
            let newEnd = newStart + (this.viewEnd - this.viewStart);

            if (newStart < 0) {
                newStart = 0;
                newEnd = newStart + (this.viewEnd - this.viewStart);
            }
            if (newEnd > this.dataset.depth) {
                newEnd = this.dataset.depth;
                newStart = newEnd - (this.viewEnd - this.viewStart);
                newStart = Math.max(0, newStart);
            }

            this.viewStart = newStart;
            this.viewEnd = newEnd;
            this.draw();
        },
        handleSpectrumAreaSelection() {
            this.spectrumSelectionMode = true;
        },
        handleSpectrumAreaAbort() {
            this.spectrumAreaStart = null;
            this.spectrumSelectionMode = false;
            this.draw();
        },
        handleClick(event) {
            if (this.hoveredFeature === null) return;

            if (this.spectrumSelectionMode && this.spectrumAreaStart == null) {
                this.spectrumAreaStart = this.hoveredFeature;
            } else {
                const start = Math.min(this.spectrumAreaStart, this.hoveredFeature);
                const end   = Math.max(this.spectrumAreaStart, this.hoveredFeature);

                this.$emit('new-spectrumarea', { start: start, end: end });
                this.handleSpectrumAreaAbort();
            }
        },
        drawTempSpectrumSelection() {
            if (!this.spectrumSelectionMode) return;
            if (this.spectrumAreaStart == null || this.hoveredFeature == null) return;

            const start = Math.max(Math.min(this.spectrumAreaStart, this.hoveredFeature), this.viewStart);
            const end   = Math.min(Math.max(this.spectrumAreaStart, this.hoveredFeature), this.viewEnd);

            const startX = this.leftPadding;
            const totalWidth = this.canvas.width - this.leftPadding - this.rightPadding;

            const startRatio = (start - this.viewStart) / (this.viewEnd - this.viewStart);
            const endRatio   = (end   - this.viewStart) / (this.viewEnd - this.viewStart);

            const xStart = startX + startRatio * totalWidth;
            const xEnd   = startX + endRatio   * totalWidth;
            const width  = xEnd - xStart;
            const height = this.canvas.height - this.xAxisHeight - this.yAxisHeight;

            this.ctx.fillStyle = 'rgb(106,0,255)';
            this.ctx.fillRect(xStart, this.yAxisHeight, width, height);
        },
        handleNewArea(newAreas) {
            this.allAreas = newAreas;
            this.draw();
        },
        drawActiveAreas() {
            if (!this.allAreas || this.allAreas.length === 0) return;

            const startX = this.leftPadding;
            const totalWidth = this.canvas.width - this.leftPadding - this.rightPadding;

            this.allAreas.forEach((area, index) => {
                if (!area.active && index !== this.hoveredAreaIndex) return;

                const clippedStart = Math.max(area.start, this.viewStart);
                const clippedEnd = Math.min(area.end, this.viewEnd);

                if (clippedStart < clippedEnd) {
                    const startRatio = (clippedStart - this.viewStart) / (this.viewEnd - this.viewStart);
                    const endRatio = (clippedEnd - this.viewStart) / (this.viewEnd - this.viewStart);
                    const xStart = startX + startRatio * totalWidth;
                    const xEnd = startX + endRatio * totalWidth;
                    const width = xEnd - xStart;
                    const height = this.canvas.height - this.xAxisHeight - this.yAxisHeight;

                    if (index === this.hoveredAreaIndex) {
                        this.ctx.fillStyle = 'rgba(150,21,21,0.5)';
                    } else {
                        this.ctx.fillStyle = 'rgba(106, 0, 255, 0.3)';
                    }

                    this.ctx.fillRect(xStart, this.yAxisHeight, width, height);
                }
            });
        },
        handleHoveredAreaIndex(index) {
            this.hoveredAreaIndex = index;
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
