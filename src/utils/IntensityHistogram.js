export default class IntensityHistogram {
    constructor(framebuffer) {
        this.histogram = [new Array(256), new Array(256)];
        this.framebuffer = framebuffer;
        // Todo add channelbounds
    }

    resetHistogram() {
        this.histogram[0].fill(0);
        this.histogram[1].fill(0);
    }

    // Todo implement channelbounds for color lense
    updateHistogram() {
        this.resetHistogram();
        let intensities = this.framebuffer.getIntensities();
        console.log(intensities);
        for (let intensityIndex = 0; intensityIndex <= intensities.length; intensityIndex = intensityIndex + 4) {

            if (intensities[intensityIndex + 3] !== 0) {
                for (let channelIndex = 0; channelIndex <= this.histogram.length; channelIndex++) {
                    // Todo continue here, fix error
                    //this.histogram[channelIndex][intensities[intensityIndex + channelIndex]]++;
                }
            }

        }
        return this.histogram;

    }
}