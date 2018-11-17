import AngleDist from './programs/AngleDist.js'
import ColorMap from './programs/ColorMap.js'
import ColorLens from './programs/ColorLens.js';
import FrameBuffer from './programs/helper/FrameBuffer.js';
import IntensitiyHistogram from './programs/helper/IntensityHistogram';

export default class RenderHandler {

    constructor(data) {
        // Set up helper to render the UI
        this.framebuffer = new FrameBuffer(data.dataWidth, data.dataHeight);
        this.intensityHistogram = new IntensitiyHistogram(this.framebuffer);
        // Init Shader
        this.angleDist = new AngleDist(this.framebuffer, this.intensityHistogram, data.canvas.width, data.canvas.height);
        this.colorMap = new ColorMap(this.framebuffer);
    }

    // Add Shader to the glmvilib to render the generated webgl pixels to the canvas
    createShader() {
        window.glmvilib.addProgram(this.angleDist);
        window.glmvilib.addProgram(this.colorMap);
    }

    // Render mouse dependend image
    render(mouse) {
        this.angleDist.updateMouse(mouse.x, mouse.y);
        window.glmvilib.render.apply(null, ['angle-dist', 'color-map']);

    }

    // Todo needed?
    getActive() {
        let active = [];
        active.push(this.angleDist.id)
    }

}