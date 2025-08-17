export default {
    data() {
        return {
            isDragging: false,
            dragStartX: 0,
            dragStartViewStart: 0,
        };
    },
    methods: {
        // Input
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

        // Drag
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
    },
};
