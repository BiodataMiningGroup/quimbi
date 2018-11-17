// Todo add description here
export default class IntensityHistogram {
    constructor(framebuffer) {
        this.histogram = new Array(256);
        this.framebuffer = framebuffer;
        // min and max value of the histogram
        this.bounds = [0, 0]
        // Todo add channelbounds
    }

    resetHistogram() {
        this.histogram.fill(0);
    }

    // Find lowest and highest value in the histogram and norm it between 0 and 1
    updateBounds() {
        this.bounds[0] = this.histogram.indexOf(Math.min.apply(0, this.histogram)) / 255;
        this.bounds[1] = this.histogram.indexOf(Math.max.apply(0, this.histogram)) / 255;
    }

    // Update the Histogram for the color values of the current pixels displayed on the screen
    updateHistogram() {
        this.resetHistogram();
        let intensities = this.framebuffer.getIntensities();
        // loop through all intensities, jump every step to the next rgba color
        for (let intensityIndex = 0; intensityIndex <= intensities.length; intensityIndex = intensityIndex + 4) {
            // if rgba has alpha being not zero, count
            if (intensities[intensityIndex + 3] !== 0) {
                for (let channelIndex = 0; channelIndex <= this.histogram.length; channelIndex++) {
                    this.histogram[intensities[intensityIndex]]++;
                }
            }
        }
        this.updateBounds();
        console.log(this.bounds);
        return this.histogram;
    }
}