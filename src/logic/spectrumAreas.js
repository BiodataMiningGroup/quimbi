export default {
    data() {
        return {
            allAreas: null,
            hoveredAreaIndex: null,
            spectrumAreaStart: null,
            spectrumSelectionMode: false,
        };
    },
    methods: {
        // Events
        handleSpectrumAreaSelection() {
            this.spectrumSelectionMode = true;
        },
        handleSpectrumAreaAbort() {
            this.spectrumAreaStart = null;
            this.spectrumSelectionMode = false;
            this.draw();
        },
        handleNewArea(newAreas) {
            this.allAreas = newAreas;
            this.draw();
        },
        handleHoveredAreaIndex(index) {
            this.hoveredAreaIndex = index;
            this.draw();
        },

        // Canvas-Click-Handler
        handleClick() {
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

        // Draw
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
    },
};
