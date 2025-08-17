export default {
    data() {
        return {
            spectrumAreas: [],
            spectrumMode: false,
        };
    },

    methods: {
        // UI
        toggleSpectrumAreaSelection() {
            this.spectrumMode = !this.spectrumMode;

            if (this.spectrumMode) {
                this.$emit('spectrum-areas-selection');
                window.addEventListener('keydown', this.handleSpectrumKeydown);
            } else {
                this.$emit('spectrum-areas-abort');
                window.removeEventListener('keydown', this.handleSpectrumKeydown);
            }
            this.renderSimilarity?.();
        },
        handleSpectrumKeydown(event) {
            if (event.key === 'Escape' && this.spectrumMode) {
                this.toggleSpectrumAreaSelection();
            }
        },

        // Interaktionen
        handleSpectrumClick(feature) {
            if (!this.spectrumMode) return;

            const start = Math.min(feature.start, feature.end);
            const end   = Math.max(feature.start, feature.end);

            const mzStart = Math.round(Number(this.dataset.channels[start]));
            const mzEnd   = Math.round(Number(this.dataset.channels[end]));

            this.spectrumAreas.push({
                name: `Spektrum: ${mzStart} – ${mzEnd}`,
                active: true, start, end
            });

            this.$emit('spectrum-areas-changed', this.spectrumAreas);
            this.spectrumMode = false;

            this.updateSpectrumMask?.();
            this.renderSimilarity?.();
        },

        // Listen Aktionen
        toggleSpectrumArea(index) {
            this.spectrumAreas[index].active = !this.spectrumAreas[index].active;
            this.$emit('spectrum-areas-changed', this.spectrumAreas);
            this.updateSpectrumMask?.();
            this.renderSimilarity?.();
        },
        deleteSpectrumArea(index) {
            this.spectrumAreas.splice(index, 1);
            this.$emit('spectrum-areas-changed', this.spectrumAreas);
            this.updateSpectrumMask?.();
            this.renderSimilarity?.();
        },

        // Utils
        getActiveSpectra() {
            const spectra = [];
            for (let i = 0; i < this.spectrumAreas.length; i++) {
                const area = this.spectrumAreas[i];
                if (area.active) {
                    spectra.push(area);
                }
            }
            return spectra;
        },
    },

    beforeUnmount() {
        window.removeEventListener('keydown', this.handleSpectrumKeydown);
    },
};
