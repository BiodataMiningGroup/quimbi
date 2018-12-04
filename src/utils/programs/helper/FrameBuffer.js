export default class FrameBuffer {

    constructor(width, height) {
        this.width = width;
        this.height = height;
        this.intensities = new Uint8Array(width * height * 4);
        this.colors = new Uint8Array(width * height * 4);
        this.spectrumValues = new Uint8Array(width * height * 4);
    }

    // Called by shader program to updated the intensities
    updateIntensities() {
        window.glmvilib.getPixels(0, 0, this.width, this.height, this.intensities);
    }

    // Todo needed?
    updateColors() {
        glmvilib.getPixels(0, 0, this.width, this.height, this.colors);
    }

    updateSpectrum() {
        window.glmvilib.getPixels(0, 0, this.width, this.height, this.spectrumValues);
    }

    getIntensities() {
        return this.intensities;
    }

}