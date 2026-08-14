import IntensityProgram from './IntensityProgram';
import fragmentShaderSourceHamming from '../shaders/similarity2bitHamming.fs';
import fragmentShaderSourceJaccard from "../shaders/similarity2bitJaccard.fs";
import fragmentShaderSourceWeightedJaccard from "../shaders/similarity2bitWeightedJaccard.fs";
import vertexShaderSource from '../shaders/rectangle.vs';


export default class Similarity2Bit extends IntensityProgram {
    constructor(options, metric) {
        const shaders = {
            hamming: {source: fragmentShaderSourceHamming, max_distance: options.depth},
            jaccard: {source: fragmentShaderSourceJaccard, max_distance: 1},
            weightedJaccard: {source: fragmentShaderSourceWeightedJaccard, max_distance: 1},
        };
        let fragmentShaderSource = shaders[metric].source;
        super(vertexShaderSource, fragmentShaderSource, options);
        this.mousePosition = [0.5, 0.5];
        this.mousePositionPointer = null;
        const tiles = Math.ceil(options.depth / 32);
        this.depthTextureWidth = Math.ceil(Math.sqrt(tiles));
        this.depthTextureHeight = Math.ceil(tiles / this.depthTextureWidth);
        this.MAX_DISTANCE = shaders[metric].max_distance;
    }

    initialize(gl, handler) {
        super.initialize(gl, handler);
        let pointer = this.getPointer();
        let normalization = gl.getUniformLocation(pointer, 'u_normalization');
        gl.uniform1f(normalization, this.MAX_DISTANCE);

        this.mousePositionPointer = gl.getUniformLocation(pointer, 'u_mouse_position');
        this.maskPointer = gl.getUniformLocation(pointer, 'u_mask');
        this.spectrumMaskPointer = gl.getUniformLocation(pointer, 'u_spectrumMask');
        this.spectrumMaskWidthPointer = gl.getUniformLocation(pointer, 'u_spectrumMaskWidth');
        this.spectrumMaskHeightPointer = gl.getUniformLocation(pointer, 'u_spectrumMaskHeight');
    }

    beforeRender(gl, handler) {
        super.beforeRender(gl, handler);
        gl.uniform2f(this.mousePositionPointer, this.mousePosition[0], this.mousePosition[1]);
        gl.activeTexture(gl.TEXTURE2);
        gl.bindTexture(gl.TEXTURE_2D, handler.getTexture('mask'));
        gl.uniform1i(this.maskPointer, 2);
        gl.activeTexture(gl.TEXTURE3);
        gl.bindTexture(gl.TEXTURE_2D, handler.getTexture('spectrumMask'));
        gl.uniform1i(this.spectrumMaskPointer, 3);
        gl.uniform1f(this.spectrumMaskWidthPointer, this.depthTextureWidth);
        gl.uniform1f(this.spectrumMaskHeightPointer, this.depthTextureHeight);
    }

    afterRender(gl, handler) {
        super.afterRender(gl, handler);
    }

    getMousePosition() {
        return this.mousePosition;
    }

    setMousePosition(position) {
        // Move position to center of pixels.
        // Flip y-coordinates because the webgl textures are flipped, too.
        this.mousePosition = [
            (position[0] + 0.5) / this.width,
            1 - (position[1] + 0.5) / this.height,
        ];
    }
}
