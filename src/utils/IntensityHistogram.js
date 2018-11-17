export default class IntensityHistogram {
    constructor(framebuffer) {
        this.histogram = new Array(256);
        this.framebuffer = framebuffer;
        // Todo add channelbounds
    }

    resetHistogram() {
        this.histogram.fill(0);
    }

    // Todo implement channelbounds for color lense
    updateHistogram() {
        this.resetHistogram();
        let intensities = this.framebuffer.getIntensities();
        // loop through all intensities, jump every step to the next rgba color
        for (let intensityIndex = 0; intensityIndex <= intensities.length; intensityIndex = intensityIndex + 4) {
            // if rgba has alpha not zero, count
            if (intensities[intensityIndex + 3] !== 0) {
                for (let channelIndex = 0; channelIndex <= this.histogram.length; channelIndex++) {
                    this.histogram[intensities[intensityIndex]]++;
                }
            }
        }
        return this.histogram;
    }
}