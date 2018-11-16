export default class FrameBuffer {
    constructor(width, height) {
        this.width = width;
        this.height = height;
        this.intensities = new Uint8Array(width * height * 4);
        this.mouseIntensities = [0, 0, 0, 0];
        this.emptyIntensities = [0, 0, 0, 0];
        this.colors = new Uint8Array(width * height * 4);
        this.mouseColors = [0, 0, 0, 0]
    }

    // Called by shader program to updated the intensities
    updateIntensities() {
        window.glmvilib.getPixels(0, 0, this.width, this.height, this.intensities);
    }

    updateColors() {
        glmvilib.getPixels(0, 0, this.width, this.height, this.colors);

    }

}