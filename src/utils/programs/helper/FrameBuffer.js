/**
 * Helper class getting and holding calculated data from the glmvilib
 */
export default class FrameBuffer {

    /**
     *
     * @param selectionInfoTextureDimension
     * @param width
     * @param height
     */
    constructor(selectionInfoTextureDimension, width, height) {
        this.width = width;
        this.height = height;
        this.selectionInfoTextureDimension = selectionInfoTextureDimension;
        this.intensities = new Uint8Array(width * height * 4);
        this.colors = new Uint8Array(width * height * 4);
        this.spectrumValues = new Uint8Array(this.selectionInfoTextureDimension * this.selectionInfoTextureDimension * 4);
    }

    /**
     * Called by shader program to updated the intensities
     */
    updateIntensities() {
        window.glmvilib.getPixels(0, 0, this.width, this.height, this.intensities);
    }

    /**
     * Called by ColorMap shader program to update colors
     */
    updateColors() {
        glmvilib.getPixels(0, 0, this.width, this.height, this.colors);
    }

    /**
     * Called in DisplayData when pixel is clicked to get spectrum data
     */
    updateSpectrum() {
        glmvilib.getPixels(0, 0, this.selectionInfoTextureDimension, this.selectionInfoTextureDimension, this.spectrumValues);
    }

    /**
     * Getter to get Itensities in the ItensityHistogram
     * @returns {Uint8Array}
     */
    getIntensities() {
        return this.intensities;
    }

}