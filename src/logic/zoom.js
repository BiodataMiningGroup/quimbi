export default {
    data() {
        return {
            zoomFactor: 2,
            yZoom: 1,
            yZoomFactor: 1.1,
        };
    },
    methods: {
        // Input
        handleWheelScroll(event) {
            event.preventDefault();

            const rect = this.canvas.getBoundingClientRect();
            const relativeX = event.clientX - rect.left - this.leftPadding;
            const contentWidth = this.canvas.width - this.leftPadding - this.rightPadding;
            const ratio = relativeX / contentWidth;

            if (event.ctrlKey) {
                // Y-Zoom
                if (event.deltaY < 0) {
                    this.yZoom *= this.yZoomFactor;
                } else {
                    this.yZoom /= this.yZoomFactor;
                }
                if (this.yZoom < 1) this.yZoom = 1;
                this.draw();
            } else {
                // X-Zoom
                if (event.deltaY < 0) this.zoomIn(ratio);
                else this.zoomOut(ratio);
            }
        },

        // Zoom
        zoomIn(ratio) {
            const range = this.viewEnd - this.viewStart;
            const newRange = Math.max(10, Math.floor(range / this.zoomFactor));
            let newStart;
            let newEnd;

            if (ratio < 0.05) {
                newStart = this.viewStart;
                newEnd = this.viewStart + newRange;
            } else if (ratio > 0.95) {
                newEnd = this.viewEnd;
                newStart = this.viewEnd - newRange;
            } else {
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
                newStart = this.viewStart;
                newEnd = this.viewStart + newRange;
            } else if (ratio > 0.95) {
                newEnd = this.viewEnd;
                newStart = this.viewEnd - newRange;
            } else {
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

        // Utils
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
            this.draw();
        },
    },
};
